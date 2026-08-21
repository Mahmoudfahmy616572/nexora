// Analyze an opportunity with a hosted LLM (Groq free tier).
//
//   POST /functions/v1/analyze
//   Authorization: Bearer <user access token>
//   {
//     "description": "<job posting text>",
//     "skills": ["Flutter", "Dart"],
//     "yearsOfExperience": 3,          // optional — derived from profile if absent
//     "education": "bachelor",         // optional — derived from profile if absent
//     "stage": "student",              // optional — candidate career stage
//     "profile": {                     // optional — grounds the recommendation in real data
//       "summary": "...",
//       "experience": [{"role": "...", "company": "...", "years": 2}],
//       "projects": [{"name": "...", "description": "...", "tech": ["..."]}],
//       "education": [{"degree": "...", "field": "..."}],
//       "certifications": ["..."],
//       "achievements": ["..."],
//       "languages": ["..."]
//     },
//     "target": {                      // optional — the CareerTarget being matched against
//       "role": "...",
//       "industry": "...",
//       "seniority": "...",
//       "countryRegion": "...",
//       "language": "..."
//     }
//   }
//
// The function EXTRACTS structured facts from the posting plus a candidate-
// specific recommendation text. All numeric scoring happens on the client via
// the deterministic OpportunityMatchEngine, so the score is always reproducible.
// The LLM key lives in the GROQ_API_KEY secret — never in the client.
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const MAX_ITEMS = 15;

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

function clampItems(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value
    .map((s: unknown) => String(s).trim())
    .filter(Boolean)
    .slice(0, MAX_ITEMS);
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
    const { data: { user } } = await supabase.auth.getUser(authHeader.replace(/^Bearer\s+/i, ''));
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
    if (Array.isArray(profile.education) && profile.education.length > 0) {
      profileLines.push(`- education: ${profile.education.map((e: Record<string, unknown>) => `${e.degree}${e.field ? ` (${e.field})` : ''}`).join('; ')}`);
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

    const target = (body.target ?? {}) as Record<string, unknown>;
    const targetLines = Object.entries(target)
      .filter(([_, v]) => v != null && String(v).trim() !== '')
      .map(([k, v]) => `- ${k}: ${String(v)}`);
    const stage = String(body.stage ?? '').trim();

    const prompt = [
      'You are a career coach and ATS expert. Extract structured facts from the job posting below.',
      'Return ONLY a JSON object with exactly these keys:',
      '- "title": the role title (string)',
      '- "company": the hiring company name, or "" if unknown (string)',
      '- "seniority": seniority level, one of "intern", "junior", "mid", "senior", "lead", "principal", or "" if unknown (string)',
      '- "location_remote": one of "remote", "on-site", "hybrid", or "" if unknown (string)',
      '- "experience_years": minimum years of experience required, 0 if not specified (number)',
      '- "education": required education level, one of "none", "high school", "associate", "bachelor", "master", "phd", "not specified" (string)',
      '- "must_have_skills": array of required skills/tools/technologies explicitly demanded (array of strings)',
      '- "nice_to_have_skills": array of preferred skills (array of strings)',
      '- "responsibilities": up to 12 key job responsibilities (array of strings)',
      '- "technologies": all technologies/tools mentioned, even if not a named "skill" (array of strings)',
      '- "certifications": required or preferred certifications, or [] if none (array of strings)',
      '- "languages": human/spoken languages required, or [] if none (array of strings)',
      '- "soft_skills": required soft skills like "communication", "leadership", or [] if none (array of strings)',
      '- "domain_knowledge": required domain knowledge like "fintech", "healthcare", or [] if none (array of strings)',
      '- "keywords": up to 8 short keyword phrases that appear important in the posting (array of strings)',
      "- \"recommendation\": 2-3 sentences of concrete, actionable advice tailored to THIS candidate. Reference the candidate's real projects, experience, and certifications when relevant to the missing requirements, and suggest exactly what to add or emphasize (string)",
      '',
      'Candidate profile:',
      `- career stage: ${stage || 'unknown'}`,
      `- skills: ${skillPool.join(', ') || 'not provided'}`,
      `- years of experience: ${years}`,
      `- education: ${education}`,
      ...(profileLines.length > 0 ? profileLines : ['- (no profile details saved yet)']),
      ...(targetLines.length > 0 ? ['Candidate target:', ...targetLines] : []),
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
        model: 'openai/gpt-oss-120b',
        temperature: 0.2,
        max_tokens: 1200,
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

    // Build the extraction-only `detail` object. Scoring is done client-side.
    const detail = {
      role: String(parsed.title ?? '').trim(),
      company: String(parsed.company ?? '').trim(),
      seniority: String(parsed.seniority ?? '').trim(),
      location_remote: String(parsed.location_remote ?? '').trim(),
      experience_years: Math.max(0, num(parsed.experience_years, 0)),
      education: String(parsed.education ?? '').toLowerCase(),
      required_skills: clampItems(parsed.must_have_skills),
      preferred_skills: clampItems(parsed.nice_to_have_skills),
      responsibilities: clampItems(parsed.responsibilities),
      technologies: clampItems(parsed.technologies),
      certifications: clampItems(parsed.certifications),
      languages: clampItems(parsed.languages),
      soft_skills: clampItems(parsed.soft_skills),
      domain_knowledge: clampItems(parsed.domain_knowledge),
      keywords: clampItems(parsed.keywords),
      raw_text: description,
    };

    return json({
      id: `ai-${crypto.randomUUID()}`,
      title: detail.role || 'Opportunity',
      company: detail.company,
      time_ago: 'Just now',
      ai_recommendation: String(parsed.recommendation ?? '').trim(),
      detail,
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
