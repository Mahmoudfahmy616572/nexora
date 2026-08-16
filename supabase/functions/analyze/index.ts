// Analyze an opportunity with a hosted LLM (Groq free tier).
//
//   POST /functions/v1/analyze
//   Authorization: Bearer <user access token>
//   {
//     "description": "<job posting text>",
//     "skills": ["Flutter", "Dart"],
//     "yearsOfExperience": 3,          // optional — derived from profile if absent
//     "education": "bachelor",         // optional — derived from profile if absent
//     "profile": {                     // optional — grounds the recommendation in real data
//       "summary": "...",
//       "experience": [{"role": "...", "company": "...", "years": 2}],
//       "projects": [{"name": "...", "description": "...", "tech": ["..."]}],
//       "education": [{"degree": "...", "field": "..."}],
//       "certifications": ["..."],
//       "achievements": ["..."],
//       "languages": ["..."]
//     }
//   }
//
// The function extracts structured facts from the posting, then computes an
// honest match score against the candidate's declared profile. The LLM key
// lives in the GROQ_API_KEY secret — never in the client.
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const EDUCATION_RANK: Record<string, number> = {
  none: 0,
  'high school': 1,
  associate: 2,
  bachelor: 3,
  master: 4,
  phd: 5,
};

function normalize(value: string): string {
  return value.toLowerCase().replace(/[^a-z0-9+#./ -]/g, '').trim();
}

function tokenize(value: string): string[] {
  return normalize(value).split(/[\s/+,.]+/).filter(Boolean);
}

function matchesSkill(userSkill: string, requiredSkill: string): boolean {
  const userTokens = tokenize(userSkill);
  const requiredTokens = tokenize(requiredSkill);
  if (userTokens.length === 0 || requiredTokens.length === 0) return false;
  // Coverage check: every meaningful token of the required skill must appear
  // somewhere in the user's skill tokens.
  for (const rt of requiredTokens) {
    const hit = userTokens.some(
      (ut) => ut === rt || ut.includes(rt) || rt.includes(ut),
    );
    if (!hit) return false;
  }
  return true;
}

function num(value: unknown, fallback: number): number {
  const n = typeof value === 'number' ? value : Number(value);
  return Number.isFinite(n) ? n : fallback;
}

function rankEducation(level: unknown): number {
  return EDUCATION_RANK[normalize(String(level ?? ''))] ?? 0;
}

function clampPct(value: number): number {
  return Math.max(0, Math.min(100, Math.round(value)));
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS });
  }

  try {
    // Require a signed-in user.
    const authHeader = req.headers.get('Authorization') ?? '';
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      return json({ error: 'Unauthorized' }, 401);
    }

    const groqKey = Deno.env.get('GROQ_API_KEY');
    if (!groqKey) {
      return json(
        { error: 'AI is not configured. Set the GROQ_API_KEY secret.' },
        503,
      );
    }

    const body = await req.json();
    const description = String(body.description ?? '').trim();
    if (!description) {
      return json({ error: 'description is required' }, 400);
    }
    const skills: string[] = Array.isArray(body.skills)
      ? body.skills.map((s: unknown) => String(s))
      : [];

    const profile = (body.profile ?? {}) as Record<string, unknown>;
    const experience = Array.isArray(profile.experience)
      ? profile.experience as Array<Record<string, unknown>>
      : [];
    const projects = Array.isArray(profile.projects)
      ? profile.projects as Array<Record<string, unknown>>
      : [];
    const educationRows = Array.isArray(profile.education)
      ? profile.education as Array<Record<string, unknown>>
      : [];

    // Skills proven by shipped projects count even if the user did not type
    // them into the manual Skills editor.
    const effectiveSkills = new Set<string>(skills);
    for (const project of projects) {
      if (Array.isArray(project.tech)) {
        for (const tech of project.tech as unknown[]) {
          const name = String(tech).trim();
          if (name) effectiveSkills.add(name);
        }
      }
    }
    const skillPool = [...effectiveSkills];

    // Prefer the explicit form value; otherwise derive from the real profile.
    const years = body.yearsOfExperience !== undefined
      ? Math.max(0, num(body.yearsOfExperience, 0))
      : experience.reduce((sum, entry) => sum + Math.max(0, num(entry.years, 0)), 0);
    const education = String(body.education ?? 'none').toLowerCase();

    const profileLines: string[] = [];
    if (String(profile.summary ?? '')) {
      profileLines.push(`- summary: ${String(profile.summary).slice(0, 600)}`);
    }
    if (experience.length > 0) {
      profileLines.push(
        `- experience: ${experience
          .map((e) => `${e.role} at ${e.company} (${e.years} yrs)`)
          .join('; ')}`,
      );
    }
    if (projects.length > 0) {
      profileLines.push(
        `- projects: ${projects
          .map((p) => `${p.name} — ${String(p.description ?? '').slice(0, 300)} (${Array.isArray(p.tech) ? p.tech.join(', ') : ''})`)
          .join(' | ')}`,
      );
    }
    if (educationRows.length > 0) {
      profileLines.push(
        `- education: ${educationRows.map((e) => `${e.degree}${e.field ? ` (${e.field})` : ''}`).join('; ')}`,
      );
    }
    if (Array.isArray(profile.certifications) && profile.certifications.length > 0) {
      profileLines.push(`- certifications: ${profile.certifications.join(', ')}`);
    }
    if (Array.isArray(profile.achievements) && profile.achievements.length > 0) {
      profileLines.push(`- achievements: ${profile.achievements.join(', ')}`);
    }
    if (Array.isArray(profile.languages) && profile.languages.length > 0) {
      profileLines.push(`- languages: ${profile.languages.join(', ')}`);
    }

    const prompt = [
      'You are a career coach and ATS expert. Extract structured facts from the job posting below,',
      'then write honest, concrete advice grounded in the candidate profile.',
      'Return ONLY a JSON object with exactly these keys:',
      '- "title": the role title (string)',
      '- "company": the hiring company name, or "" if unknown (string)',
      '- "experience_years": minimum years of experience required, 0 if not specified (number)',
      '- "education": required education level, one of "none", "high school", "associate", "bachelor", "master", "phd", "not specified" (string)',
      '- "must_have_skills": array of required skills/tools/technologies explicitly demanded (array of strings)',
      '- "nice_to_have_skills": array of preferred skills (array of strings)',
      '- "keywords": up to 8 short keyword phrases that appear important in the posting (array of strings)',
      "- \"recommendation\": 2-3 sentences of concrete, actionable advice tailored to THIS candidate. Reference the candidate's real projects, experience, and certifications when they are relevant to the missing requirements, and suggest exactly what to add or emphasize (string)",
      '',
      'Candidate profile:',
      `- skills: ${skillPool.join(', ') || 'not provided'}`,
      `- years of experience: ${years}`,
      `- education: ${education}`,
      ...(profileLines.length > 0 ? profileLines : ['- (no profile details saved yet)']),
      '',
      'Job posting:',
      '"""',
      description.slice(0, 12000),
      '"""',
    ].join('\n');

    const ai = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${groqKey}`,
      },
      body: JSON.stringify({
        model: 'llama-3.3-70b-versatile',
        temperature: 0.2,
        max_tokens: 900,
        response_format: { type: 'json_object' },
        messages: [{ role: 'user', content: prompt }],
      }),
    });

    if (!ai.ok) {
      const detail = await ai.text();
      console.error('groq error', ai.status, detail);
      return json({ error: 'AI request failed' }, 502);
    }

    const aiData = await ai.json();
    const content = aiData?.choices?.[0]?.message?.content ?? '';
    let parsed: Record<string, unknown>;
    try {
      parsed = JSON.parse(content);
    } catch {
      return json({ error: 'AI returned malformed output' }, 502);
    }

    const mustHave = (parsed.must_have_skills ?? []).map((s: unknown) => String(s)).filter(Boolean);
    const niceToHave = (parsed.nice_to_have_skills ?? []).map((s: unknown) => String(s)).filter(Boolean);
    const keywords = (parsed.keywords ?? []).map((s: unknown) => String(s)).filter(Boolean);
    const requiredYears = Math.max(0, num(parsed.experience_years, 0));
    const requiredEduRank = rankEducation(parsed.education);

    // Deterministic scoring against the candidate's real profile.
    const coveredMust = mustHave.filter((m) => skillPool.some((s) => matchesSkill(s, m)));
    const missing = mustHave.filter((m) => !coveredMust.includes(m));
    const strong = [...coveredMust, ...niceToHave.filter((n) => skillPool.some((s) => matchesSkill(s, n)))];

    const skillsScore = mustHave.length === 0
      ? 90
      : clampPct((coveredMust.length / mustHave.length) * 100);

    const expScore = requiredYears === 0
      ? 100
      : clampPct(Math.min(1, years / requiredYears) * 100);

    const eduScore = requiredEduRank === 0
      ? 100
      : rankEducation(education) >= requiredEduRank
        ? 100
        : 60;

    const coveredKeywords = keywords.filter((k) => skillPool.some((s) => matchesSkill(s, k)));
    const keywordsScore = keywords.length === 0
      ? 85
      : clampPct((coveredKeywords.length / keywords.length) * 100);

    const overall = clampPct(
      skillsScore * 0.45 + expScore * 0.25 + eduScore * 0.15 + keywordsScore * 0.15,
    );

    return json({
      id: `ai-${crypto.randomUUID()}`,
      title: String(parsed.title ?? 'Opportunity'),
      company: String(parsed.company ?? ''),
      time_ago: 'Just now',
      overall,
      skills: skillsScore,
      experience: expScore,
      education: eduScore,
      keywords: keywordsScore,
      strong,
      missing,
      ai_recommendation: String(parsed.recommendation ?? ''),
    });
  } catch (err) {
    console.error('analyze failed', err);
    return json({ error: String(err) }, 500);
  }
});

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...CORS, 'Content-Type': 'application/json' },
  });
}
