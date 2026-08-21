// Evaluate a CV and produce improvement suggestions.
//
//   POST /functions/v1/cv_evaluate
//   Authorization: Bearer <user access token>
//   {
//     "content": { ...CvContent },        // the CV being evaluated
//     "target": { "role": "...", ... },    // optional CareerTarget
//     "analysis": { ...JobAnalysis },       // optional (strong/missing/keywords)
//     "opportunity": { ...OpportunityAnalysis } // optional (requirements+status)
//   }
//
// The function returns ONLY qualitative explanations and improvement
// suggestions. It does NOT compute the numeric scores — those are produced
// deterministically client-side so the AI can never manipulate the final score.
// The LLM key lives in GROQ_API_KEY and is never sent to the client.
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

const CATEGORIES = [
  'overall',
  'sectionCompleteness',
  'structure',
  'contentStrength',
  'evidenceStrength',
  'readability',
  'clarity',
  'ats',
  'keywordAlignment',
  'skillAlignment',
  'targetAlignment',
];

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS });
  }

  try {
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

    const body = await req.json().catch(() => ({}));
    const content = (body.content ?? {}) as Record<string, unknown>;
    const target = (body.target ?? {}) as Record<string, unknown>;
    const analysis = (body.analysis ?? {}) as Record<string, unknown>;
    const opportunity = (body.opportunity ?? {}) as Record<string, unknown>;

    const header = (content.header ?? {}) as Record<string, unknown>;
    const summary = str(content.summary);
    const experience = list(content.experience).map((e) =>
      e as Record<string, unknown>
    );
    const projects = list(content.projects).map((p) =>
      p as Record<string, unknown>
    );
    const education = list(content.education).map((e) =>
      e as Record<string, unknown>
    );
    const skillGroups = list(content.skillGroups).map((g) =>
      g as Record<string, unknown>
    );
    const certifications = list(content.certifications).map((c) =>
      c as Record<string, unknown>
    );
    const achievements = list(content.achievements).map((a) =>
      a as Record<string, unknown>
    );
    const languages = list(content.languages).map((l) =>
      l as Record<string, unknown>
    );

    const facts: string[] = [];
    if (str(header.name)) facts.push(`- name: ${str(header.name)}`);
    if (str(header.email)) facts.push(`- email: ${str(header.email)}`);
    if (str(header.phone)) facts.push(`- phone: ${str(header.phone)}`);
    if (summary) facts.push(`- summary: ${summary.slice(0, 800)}`);
    if (experience.length) {
      facts.push(
        '- experience: ' +
          experience
            .map((e) =>
              `${str(e.role)} at ${str(e.company)} — ${
                str(e.description).slice(0, 400)
              }`)
            .join(' | '),
      );
    }
    if (projects.length) {
      facts.push(
        '- projects: ' +
          projects
            .map((p) =>
              `${str(p.name)} — ${str(p.description).slice(0, 400)} (tech: ${
                list(p.tech).map(String).join(', ')
              })`)
            .join(' | '),
      );
    }
    if (education.length) {
      facts.push(
        '- education: ' +
          education
            .map((e) =>
              `${str(e.degree)}${str(e.field) ? ` (${str(e.field)})` : ''}`)
            .join('; '),
      );
    }
    if (skillGroups.length) {
      facts.push(
        '- skills: ' +
          skillGroups
            .map((g) =>
              `${str(g.title)}: ${
                list(g.skills).map(String).join(', ')
              }`)
            .join(' | '),
      );
    }
    if (certifications.length) {
      facts.push(
        '- certifications: ' +
          certifications.map((c) => str(c.name)).join(', '),
      );
    }
    if (achievements.length) {
      facts.push(
        '- achievements: ' +
          achievements.map((a) => str(a.text)).join(' | '),
      );
    }
    if (languages.length) {
      facts.push(
        '- languages: ' +
          languages.map((l) => str(l.name)).join(', '),
      );
    }

    const targetLines = Object.entries(target)
      .filter(([, v]) => v != null && str(v) !== '')
      .map(([k, v]) => `- ${k}: ${str(v)}`);

    const oppRequirements = list(opportunity.requirements).map((r) =>
      r as Record<string, unknown>
    );
    const reqLines = oppRequirements.map((r) =>
      `- requirement: ${str(r.label)} (required: ${r.required}, status: ${
        str(r.status)
      })`
    );
    const strongList = list(analysis.strong).map(String);
    const missingList = list(analysis.missing).map(String);
    const kwList = list(analysis.keywords).map(String);

    const prompt = [
      'You are a CV evaluation assistant. You ONLY explain problems and propose',
      'rewordings of EXISTING text. You must NEVER invent, guess, or embellish',
      'any fact.',
      '',
      'STRICT RULES:',
      '1. The CV (FACTS below) is the source of truth.',
      '2. The target/opportunity context is NOT evidence the candidate has',
      '   those skills — it only tells you what the role wants.',
      '3. Never invent employment, employers, job titles, years, degrees,',
      '   universities, certifications, achievements, projects, technologies,',
      '   responsibilities, metrics, dates, clients, users, revenue, or teams.',
      '4. Never turn a requirement into a candidate skill.',
      '5. Never turn a project into professional experience.',
      '6. Never create metrics (no "team of 5", no "+12%", no "1M users").',
      '7. A personal project remains a personal project.',
      '8. Each suggestion\'s "current" field MUST be copied VERBATIM from the',
      '   CV FACTS above (an exact substring). "suggested" MUST be a rewording',
      '   of that same "current" text — preserving every fact, only improving',
      '   wording, clarity, or order. Do NOT change meaning or add claims.',
      '9. Only propose suggestions for content that actually exists in FACTS.',
      '10. Do not propose changes to facts themselves — only to their wording.',
      '',
      'Return ONLY a JSON object with this exact shape:',
      '{',
      '  "explanations": {',
      ...CATEGORIES.map((c) => `    "${c}": string,`),
      '  },',
      '  "suggestions": [',
      '    {',
      '      "section": "summary|experience|projects|education|skills|certifications|achievements|languages|header",',
      '      "problem": string,',
      '      "current": string,', // exact verbatim snippet from FACTS
      '      "suggested": string,', // rewording of current
      '      "why": string,',
      '      "targetRequirement": string',
      '    }',
      '  ]',
      '}',
      '',
      'Rules for the JSON:',
      '- "explanations" must contain ALL of these keys: ' +
        CATEGORIES.join(', '),
      '- Each explanation is 1–2 sentences, concrete and specific.',
      '- "suggestions" should be few and high-value (0–6). Empty list is fine.',
      '- "current" must appear verbatim in FACTS; do not paraphrase it.',
      '',
      'FACTS (the CV):',
      ...(facts.length ? facts : ['- (no CV content saved yet)']),
      ...(targetLines.length ? ['TARGET:', ...targetLines] : []),
      ...(reqLines.length ? ['OPPORTUNITY REQUIREMENTS:', ...reqLines] : []),
      ...(strongList.length ? [`STRONG (candidate has): ${strongList.join(', ')}`] : []),
      ...(missingList.length ? [`MISSING (role wants): ${missingList.join(', ')}`] : []),
      ...(kwList.length ? [`KEYWORDS: ${kwList.join(', ')}`] : []),
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
        max_tokens: 1800,
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
    const text = aiData?.choices?.[0]?.message?.content ?? '';
    let parsed: Record<string, unknown>;
    try {
      parsed = JSON.parse(text);
    } catch {
      return json({ error: 'AI returned malformed output' }, 502);
    }

    return json({
      explanations: parsed.explanations ?? {},
      suggestions: parsed.suggestions ?? [],
    });
  } catch (err) {
    console.error('cv_evaluate failed', err);
    return json({ error: String(err) }, 500);
  }
});
