// Draft a full Career DNA profile from a few quick facts with a hosted LLM
// (Groq free tier).
//
//   POST /functions/v1/profile_draft
//   Authorization: Bearer <user access token>
//   {
//     "target": "mobile developer",
//     "education": "computer engineering",
//     "experience": "built a tracking app, 1 internship",
//     "skills": "Flutter, Dart, Firebase"
//   }
//
// Returns a complete, honest draft (summary, experience, projects, education,
// certifications, achievements, languages, skills) the user can review and
// edit before saving. The LLM key lives in GROQ_API_KEY — never in the client.
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

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
    const notes = [
      `Target role: ${String(body.target ?? '').trim()}`,
      `Education: ${String(body.education ?? '').trim()}`,
      `What the candidate has done: ${String(body.experience ?? '').trim()}`,
      `Skills / tech: ${String(body.skills ?? '').trim()}`,
    ].filter((line) => !line.endsWith(':')).join('\n');

    if (!notes) {
      return json({ error: 'Tell me something about yourself first' }, 400);
    }

    const prompt = [
      'You are a career coach helping a candidate build their first CV profile from scratch.',
      'From the notes below, write a realistic, honest, concrete profile draft.',
      'Do NOT invent facts the notes do not imply — if something is unknown, leave that item out.',
      'Experience years are whole numbers; unpaid work, internships, and student projects count as experience entries.',
      "Projects must include a short \"description\" of what it does and the candidate's part, and a \"tech\" array.",
      'Return ONLY a JSON object with exactly these keys:',
      '- "summary": 2-3 sentences (string)',
      '- "experience": array of {"role": string, "company": string, "years": number}',
      '- "projects": array of {"name": string, "description": string, "tech": [string]}',
      '- "education": array of {"degree": string, "field": string}',
      '- "certifications": array of strings',
      '- "achievements": array of short, specific strings',
      '- "languages": array of strings',
      '- "skills": array of strings (the concrete technologies/skills to list)',
      '',
      'Candidate notes:',
      notes.slice(0, 4000),
    ].join('\n');

    const ai = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${groqKey}`,
      },
      body: JSON.stringify({
        model: 'llama-3.3-70b-versatile',
        temperature: 0.4,
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
      parsed = JSON.parse(content);
    } catch {
      return json({ error: 'AI returned malformed output' }, 502);
    }

    const cleanArray = (value: unknown) =>
      Array.isArray(value) ? value.map((v) => String(v)).filter(Boolean) : [];

    return json({
      summary: String(parsed.summary ?? ''),
      experience: Array.isArray(parsed.experience) ? parsed.experience : [],
      projects: Array.isArray(parsed.projects) ? parsed.projects : [],
      education: Array.isArray(parsed.education) ? parsed.education : [],
      certifications: cleanArray(parsed.certifications),
      achievements: cleanArray(parsed.achievements),
      languages: cleanArray(parsed.languages),
      skills: cleanArray(parsed.skills),
    });
  } catch (err) {
    console.error('profile_draft failed', err);
    return json({ error: String(err) }, 500);
  }
});

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...CORS, 'Content-Type': 'application/json' },
  });
}
