// Generate a tailored CV from verified Career DNA + Career Target.
//
//   POST /functions/v1/cv_generate
//   Authorization: Bearer <user access token>
//   {
//     "career_dna": { ... },          // factual source of truth
//     "target": { "role": "...", ... },
//     "opportunity": { ... },          // optional OpportunityAnalysis
//     "template": { "id": "..." },
//     "language": "en" | "ar"
//   }
//
// The function is responsible ONLY for wording, prioritization, ordering,
// semantic tailoring, summary generation, and bullet restructuring. It is NOT
// responsible for factual data creation. All scoring/validation happens client-
// side via CvContentValidator. The LLM key lives in GROQ_API_KEY — never sent
// to the client.
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...CORS, 'Content-Type': 'application/json' },
  });
}

function str(value: unknown): string {
  return value == null ? '' : String(value).trim();
}

function list(value: unknown): unknown[] {
  return Array.isArray(value) ? (value as unknown[]) : [];
}

function extractJson(text: string): Record<string, unknown> {
  const t = (text ?? '').trim();
  try {
    return JSON.parse(t) as Record<string, unknown>;
  } catch {
    const start = t.indexOf('{');
    const end = t.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return JSON.parse(t.slice(start, end + 1)) as Record<string, unknown>;
    }
    throw new Error('AI returned malformed output');
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS });
  }

  try {
    // Require a signed-in user; never trust a client-supplied user_id.
    const authHeader = req.headers.get('Authorization') ?? '';
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const token = authHeader.replace(/^Bearer\s+/i, '');
    const { data: { user } } = await supabase.auth.getUser(token);
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

    const body = await req.json().catch(() => ({}));
    const dna = (body.career_dera ?? body.career_dna ?? {}) as Record<string, unknown>;
    const target = (body.target ?? {}) as Record<string, unknown>;
    const opportunity = (body.opportunity ?? {}) as Record<string, unknown>;
    const template = (body.template ?? {}) as Record<string, unknown>;
    const language = String(body.language ?? 'en').toLowerCase();

    const profile = (dna.profile ?? dna.content ?? {}) as Record<string, unknown>;
    const experience = list(profile.experience).map((e) =>
      e as Record<string, unknown>
    );
    const projects = list(profile.projects).map((p) =>
      p as Record<string, unknown>
    );
    const education = list(profile.education).map((e) =>
      e as Record<string, unknown>
    );
    const skills = list(dna.skills).map((s) => String(s));
    const certifications = list(profile.certifications).map((c) => String(c));
    const achievements = list(profile.achievements).map((a) => String(a));
    const languages = list(profile.languages).map((l) => String(l));
    const summary = str(profile.summary);

    const facts: string[] = [];
    if (summary) facts.push(`- summary: ${summary.slice(0, 800)}`);
    if (experience.length) {
      facts.push(
        `- professional_experience: ${
          experience
            .map((e) =>
              `${str(e.role)} at ${str(e.company)} (${str(e.years)} yrs)`
            )
            .join('; ')
        }`,
      );
    }
    if (projects.length) {
      facts.push(
        `- projects: ${
          projects
            .map((p) =>
              `${str(p.name)} — ${str(p.description).slice(0, 400)} (tech: ${
                list(p.tech).map(String).join(', ')
              })`
            )
            .join(' | ')
        }`,
      );
    }
    if (education.length) {
      facts.push(
        `- education: ${
          education
            .map((e) => `${str(e.degree)}${str(e.field) ? ` (${str(e.field)})` : ''}`)
            .join('; ')
        }`,
      );
    }
    if (skills.length) facts.push(`- skills: ${skills.join(', ')}`);
    if (certifications.length) {
      facts.push(`- certifications: ${certifications.join(', ')}`);
    }
    if (achievements.length) {
      facts.push(`- achievements: ${achievements.join(' | ')}`);
    }
    if (languages.length) facts.push(`- languages: ${languages.join(', ')}`);

    const targetLines = Object.entries(target)
      .filter(([, v]) => v != null && str(v) !== '')
      .map(([k, v]) => `- ${k}: ${str(v)}`);

    const oppLines = Object.entries(opportunity)
      .filter(([, v]) => v != null && str(v) !== '')
      .map(([k, v]) => `- ${k}: ${str(v)}`);

    const prompt = [
      'You are a CV writing assistant. Your ONLY job is to reword, reorder,',
      'prioritize, and tailor EXISTING facts into a clean CV. You must NEVER',
      'invent, guess, or embellish any fact.',
      '',
      'STRICT RULES:',
      '1. CareerDna (below) is the factual source of truth.',
      '2. The target is contextual only — it is NOT evidence the candidate',
      '   possesses those skills.',
      '3. Opportunity requirements are NOT evidence the candidate has them.',
      '4. Never turn a requirement into a candidate skill.',
      '5. Never invent employment, employers, job titles, years, degrees,',
      '   universities, certifications, achievements, projects, technologies,',
      '   responsibilities, metrics, dates, clients, users, revenue, or',
      '   team sizes.',
      '6. Never create professional experience from projects.',
      '7. Never create metrics (no "team of 5", no "+12%", no "1M users").',
      '8. Unknown information must be OMITTED, never guessed.',
      '9. Only improve wording, structure, prioritization, and alignment.',
      '10. Preserve factual distinctions: professional experience vs project',
      '    experience vs education vs certification vs achievement.',
      '11. A fresh graduate must remain a fresh graduate. A student remains a',
      '    student. A personal project remains a personal project.',
      '',
      `Respond in ${language === 'ar' ? 'Arabic' : 'English'}.`,
      '',
      'Return ONLY a JSON object with this exact shape:',
      '{',
      '  "header": { "name": "", "title": "", "subtitle": "", "email": "", "phone": "", "location": "", "links": [] },',
      '  "summary": string,',
      '  "experience": [ { "role": "", "company": "", "years": number|null, "startDate": "", "endDate": "", "description": "" } ],',
      '  "projects": [ { "name": "", "description": "", "tech": [string], "link": "" } ],',
      '  "education": [ { "degree": "", "field": "", "institution": "", "year": "" } ],',
      '  "skillGroups": [ { "title": "", "skills": [string] } ],',
      '  "certifications": [ { "name": "", "issuer": "", "year": "" } ],',
      '  "achievements": [ { "text": "" } ],',
      '  "languages": [ { "name": "", "level": "" } ]',
      '}',
      '',
      'Rules for the JSON:',
      '- Only include sections whose source facts exist; omit empty arrays.',
      '- "header.name" must be empty unless explicitly provided.',
      '- Keep every value a direct rephrasing of a provided fact.',
      '- "skillGroups" should group the provided skills sensibly.',
      '',
      'FACTS (CareerDna):',
      ...(facts.length ? facts : ['- (no career DNA facts saved yet)']),
      ...(targetLines.length ? ['TARGET:', ...targetLines] : []),
      ...(oppLines.length ? ['OPPORTUNITY:', ...oppLines] : []),
      `TEMPLATE: ${str(template.id) || 'nexoraMinimal'}`,
    ].join('\n');

    const ai = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${groqKey}`,
      },
      body: JSON.stringify({
        model: 'openai/gpt-oss-120b',
        temperature: 0.3,
        max_tokens: 1600,
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
      parsed = extractJson(content);
    } catch {
      return json({ error: 'AI returned malformed output' }, 502);
    }

    return json({
      content: parsed,
      sourceLabel: 'AI tailored',
      template_id: str(template.id) || 'nexoraMinimal',
    });
  } catch (err) {
    console.error('cv_generate failed', err);
    return json({ error: String(err) }, 500);
  }
});
