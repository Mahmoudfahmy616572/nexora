// Supabase Edge Function: build_profile
//
// Turns a few tap-first choices into a complete, editable career profile using
// an LLM. This mirrors how `analyze` works — the Flutter client calls
// `runAiProfileBuild` and gracefully falls back to the local generator when the
// function is missing, unconfigured, or offline.
//
// Deploy:
//   supabase functions deploy build_profile --no-verify-jwt
//   supabase secrets set GROQ_API_KEY=gsk_...
//
// Request body:
//   {
//     "interests": ["programming", "design"],
//     "customInterests": ["Robotics"],
//     "goals": ["internship", "job"],
//     "sentence": "optional free text from the user"
//   }
//
// Response body:
//   {
//     "skills": ["Flutter", "Dart", "..."],
//     "profile": { "summary": "...", "experience": [...], "projects": [...],
//                  "education": [...], "certifications": [...],
//                  "achievements": [...], "languages": ["Arabic", "English"] }
//   }

// Groq's API is OpenAI-compatible; we just point at its endpoint and use one of
// its models. Swap MODEL to any Groq chat model that supports JSON mode.
const GROQ_MODEL = 'llama-3.3-70b-versatile';
const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions';

Deno.serve(async (req) => {
  // CORS — allow the Supabase client (browser) to call this function.
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders() });
  }

  try {
    const body = (await req.json()) as {
      interests?: unknown;
      customInterests?: unknown;
      goals?: unknown;
      sentence?: unknown;
    };
    const { interests, customInterests, goals, sentence } = body;

    const apiKey = Deno.env.get('GROQ_API_KEY');
    if (!apiKey) {
      return json({ error: 'GROQ_API_KEY is not configured' }, 500);
    }

    const system = [
      'You are Nexora, a career profile builder for students and early-career',
      'people who have no CV yet. You turn a few interests, goals, and an',
      'optional free-text sentence into a complete, believable, editable career',
      'profile. Be realistic for someone at the START of their career: use',
      'student clubs, university projects, traineeships, and coursework — never',
      'invent a full-time senior history. Keep everything concise and specific.',
      '',
      'Return ONLY valid minified JSON (no markdown, no commentary) matching',
      'exactly this shape:',
      '{',
      '  "skills": ["Skill1", "Skill2", ...],',
      '  "profile": {',
      '    "summary": "2-3 sentence first-person summary",',
      '    "experience": [{"role": "...", "company": "...", "years": 0, "description": "..."}],',
      '    "projects": [{"name": "...", "description": "...", "tech": ["...", "..."]}],',
      '    "education": [{"degree": "...", "field": "...", "school": "...", "year": 202X}],',
      '    "certifications": ["..."],',
      '    "achievements": ["..."],',
      '    "languages": ["Arabic", "English"]',
      '  }',
      '}',
      '',
      'Rules:',
      '- skills: 6-10 concrete, role-relevant skills.',
      '- experience: 1-3 entries, all entry-level / student context.',
      '- projects: 1-2, tied to the chosen interests or the free-text sentence.',
      '- education: 1 entry reflecting a typical degree for the chosen interests.',
      '- If a custom interest is given and not a known field, infer a sensible role.',
      '- If a free-text sentence is provided, let it reshape the output.',
    ].join('\n');

    const userParts = [];
    if (Array.isArray(interests) && interests.length) {
      userParts.push(`Interests: ${interests.join(', ')}.`);
    }
    if (Array.isArray(customInterests) && customInterests.length) {
      userParts.push(`Custom interests: ${customInterests.join(', ')}.`);
    }
    if (Array.isArray(goals) && goals.length) {
      userParts.push(`Goals: ${goals.join(', ')}.`);
    }
    if (sentence && sentence.trim()) {
      userParts.push(`About the user: ${sentence.trim()}`);
    }
    if (!userParts.length) {
      userParts.push('No specific interests provided — produce a sensible generic student profile.');
    }

    const completion = await fetch(GROQ_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: GROQ_MODEL,
        temperature: 0.7,
        response_format: { type: 'json_object' },
        messages: [
          { role: 'system', content: system },
          { role: 'user', content: userParts.join('\n') },
        ],
      }),
    });

    if (!completion.ok) {
      const detail = await completion.text();
      return json({ error: `LLM request failed: ${detail}` }, 502);
    }

    const payload = await completion.json();
    const content = payload?.choices?.[0]?.message?.content ?? '';
    const parsed = parseJsonSafe(content);
    if (!parsed || !Array.isArray(parsed.skills) || !parsed.profile) {
      return json({ error: 'LLM returned an invalid profile shape' }, 502);
    }

    return json({
      skills: parsed.skills,
      profile: parsed.profile,
    });
  } catch (err) {
    return json({ error: err instanceof Error ? err.message : String(err) }, 400);
  }
});

function parseJsonSafe(text: string): Record<string, unknown> | null {
  const trimmed = (text ?? '').trim();
  try {
    return JSON.parse(trimmed);
  } catch {
    // tolerate ```json ... ``` fences if the model ignores response_format.
    const match = trimmed.match(/```(?:json)?\s*([\s\S]*?)```/i);
    if (match) {
      try {
        return JSON.parse(match[1].trim());
      } catch {
        return null;
      }
    }
    return null;
  }
}

function corsHeaders(): Record<string, string> {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers':
      'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  };
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    headers: { ...corsHeaders(), 'Content-Type': 'application/json' },
    status,
  });
}
