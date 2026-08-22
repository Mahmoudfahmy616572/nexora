// Contextual, multi-turn Career DNA interview.
//
//   POST /functions/v1/career_interview
//   Authorization: Bearer <user access token>
//   {
//     "context": { "target": "...", "summary": "...", "education": [...], ... },
//     "history": [ { "q": "...", "a": "..." } ],
//     "language": "en",
//     "finish": false
//   }
//
// Returns either:
//   { "done": false, "question": "..." }            -> ask the user this question
//   { "done": true,  "profile": { summary, experience, projects, ... } }
//
// Interview prep mode (Phase 4): send "mode": "interview_plan" plus
//   "focusAreas": ["..."], "targetRole": "...", "company": "..."
// and it returns:
//   { "done": true, "plan": { "focusAreas": [{requirement, why, question,
//      coaching}], "likelyQuestions": [...], "tips": "..." } }
//
// The LLM key lives in GROQ_API_KEY — never in the client.
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
    const { data: { user } } = await supabase.auth.getUser(authHeader.replace(/^Bearer\s+/i, ''));
    if (!user) {
      return json({ error: 'Unauthorized' }, 401);
    }

    const groqKey = Deno.env.get('GROQ_API_KEY');
    if (!groqKey) {
      return json({ error: 'AI is not configured. Set the GROQ_API_KEY secret.' }, 503);
    }

    const body = await req.json();
    const context = body.context ?? {};
    const history = Array.isArray(body.history) ? body.history : [];
    const language = String(body.language ?? 'en');
    const finish = Boolean(body.finish);
    const mode = String(body.mode ?? 'profile_build');
    const isPlan = mode === 'interview_plan';
    const focusAreas = Array.isArray(body.focusAreas)
      ? body.focusAreas.map((f: unknown) => String(f)).filter(Boolean)
      : [];
    const targetRole = String(body.targetRole ?? '');
    const company = String(body.company ?? '');

    const contextText = [
      `Target role: ${String(context.target ?? '').trim()}`,
      `Target industry: ${String(context.targetIndustry ?? '').trim()}`,
      `Career stage: ${String(context.stage ?? '').trim()}`,
      `Summary: ${String(context.summary ?? '').trim()}`,
      `Education: ${
        Array.isArray(context.education)
          ? context.education.map((e: Record<string, unknown>) =>
            `${e.degree ?? ''} ${e.field ?? ''}`.trim()
          ).join('; ')
          : ''
      }`,
      `Experience: ${
        Array.isArray(context.experience)
          ? context.experience.map((e: Record<string, unknown>) =>
            `${e.role ?? ''} at ${e.company ?? ''} (${e.years ?? 0}y)`.trim()
          ).join('; ')
          : ''
      }`,
      `Projects: ${
        Array.isArray(context.projects)
          ? context.projects.map((p: Record<string, unknown>) =>
            `${p.name ?? ''}: ${p.description ?? ''} [${Array.isArray(p.tech) ? p.tech.join(', ') : ''}]`
          ).join('; ')
          : ''
      }`,
      `Skills: ${Array.isArray(context.skills) ? context.skills.join(', ') : ''}`,
      `Certifications: ${Array.isArray(context.certifications) ? context.certifications.join(', ') : ''}`,
      `Achievements: ${Array.isArray(context.achievements) ? context.achievements.join(', ') : ''}`,
      `Languages: ${Array.isArray(context.languages) ? context.languages.join(', ') : ''}`,
    ].filter((l) => !l.endsWith(':')).join('\n');

    const historyText = history
      .map((h: Record<string, unknown>, i: number) =>
        `Q${i + 1}: ${String(h.q ?? '')}\nA${i + 1}: ${String(h.a ?? '')}`
      )
      .join('\n');

    const turnInstruction = finish
      ? 'The candidate chose to finish. Produce the final structured profile now.'
      : (history.length >= 6
        ? 'You have enough signal. Produce the final structured profile now (set done=true).'
        : 'Ask the single most useful NEXT question to draw out missing, concrete detail. Do not repeat prior questions.');

    const prompt = isPlan ? [
      'You are a concise, honest interview coach preparing ONE candidate for a specific role.',
      `Respond in ${language === 'ar' ? 'Arabic' : 'English'}.`,
      'Ground rules:',
      '- Base everything ONLY on the candidate context below, the listed focus areas, and well-known general interview practice.',
      '- NEVER invent facts about the candidate (companies, dates, degrees, metrics, achievements).',
      '- Be specific and practical; prefer STAR-style preparation advice.',
      '',
      'Return ONLY a JSON object exactly:',
      '{ "plan": { "focusAreas": [{"requirement": string, "why": string, "question": string, "coaching": string}], "likelyQuestions": [string], "tips": string } }',
      '- focusAreas: 3-6 items covering the provided focus areas. why = one sentence explaining why it matters for THIS role grounded in the gap; question = one realistic interviewer question for it; coaching = 1-2 sentences of concrete prep advice.',
      '- likelyQuestions: up to 5 additional likely interview questions for this role and company.',
      '- tips: one short paragraph of overall preparation tips.',
      '',
      `Target role: ${targetRole}`,
      company ? `Company: ${company}` : 'Company: (unknown)',
      `Focus areas:\n${focusAreas.length ? focusAreas.map((f: string) => `- ${f}`).join('\n') : '- (none provided; infer the most important areas from the candidate context)'}`,
      '',
      'Candidate context:',
      contextText,
    ].join('\n') : [
      'You are a warm, concise career coach running a short interview to build a candidate\'s Career DNA.',
      `Respond in ${language === 'ar' ? 'Arabic' : 'English'}.`,
      'Rules:',
      '- Ask ONE question at a time. Be specific and contextual to what the candidate already shared.',
      '- NEVER invent companies, roles, dates, degrees, certifications, projects, achievements, technologies or metrics.',
      '- Only use facts the candidate explicitly stated in their answers or context.',
      '- If the candidate has no professional experience, pivot to projects, coursework, internships, volunteering or certifications — never imply they have a job they did not mention.',
      '- Prefer questions that extract: responsibilities, technical skills, measurable impact, projects, achievements, education, goals, preferences, or transferable skills.',
      '',
      'Return ONLY a JSON object, exactly one of:',
      '- { "done": false, "question": "<the next question>" }',
      '- { "done": true, "profile": { "summary": string, "experience": [{"role","company","years"}], "projects": [{"name","description","tech":[]}], "education": [{"degree","field"}], "certifications": [], "achievements": [], "languages": [], "skills": [] } }',
      '',
      'Candidate context:',
      contextText,
      '',
      'Conversation so far:',
      historyText || '(none)',
      '',
      turnInstruction,
    ].join('\n');

    const ai = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${groqKey}`,
      },
      body: JSON.stringify({
        model: 'openai/gpt-oss-120b',
        temperature: 0.5,
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

    if (isPlan) {
      const p = parsed.plan;
      if (!p || typeof p !== 'object') {
        return json({ error: 'AI returned malformed plan' }, 502);
      }
      const plan = p as Record<string, unknown>;
      const rawAreas = Array.isArray(plan.focusAreas) ? plan.focusAreas : [];
      const areas = rawAreas
        .map((f) => {
          const o = f && typeof f === 'object'
            ? f as Record<string, unknown>
            : {};
          return {
            requirement: String(o.requirement ?? ''),
            why: String(o.why ?? ''),
            question: String(o.question ?? ''),
            coaching: String(o.coaching ?? ''),
          };
        })
        .filter((f) => Boolean(f.requirement));
      return json({
        done: true,
        plan: {
          focusAreas: areas,
          likelyQuestions: cleanArray(plan.likelyQuestions),
          tips: String(plan.tips ?? ''),
        },
      });
    }

    if (parsed.done === true) {
      return json({
        done: true,
        profile: {
          summary: String(parsed.profile?.summary ?? ''),
          experience: Array.isArray(parsed.profile?.experience) ? parsed.profile.experience : [],
          projects: Array.isArray(parsed.profile?.projects) ? parsed.profile.projects : [],
          education: Array.isArray(parsed.profile?.education) ? parsed.profile.education : [],
          certifications: cleanArray(parsed.profile?.certifications),
          achievements: cleanArray(parsed.profile?.achievements),
          languages: cleanArray(parsed.profile?.languages),
          skills: cleanArray(parsed.profile?.skills),
        },
      });
    }

    return json({ done: false, question: String(parsed.question ?? '') });
  } catch (err) {
    console.error('career_interview failed', err);
    return json({ error: String(err) }, 500);
  }
});

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...CORS, 'Content-Type': 'application/json' },
  });
}
