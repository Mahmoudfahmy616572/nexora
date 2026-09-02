// AI Enhance CareerDNA — improves weak areas based on analysis gaps.
//
//   POST /functions/v1/ai_enhance
//   Authorization: Bearer <user access token>
//
//   {
//     "dna": { "skills": [...], "profile": { ... } },
//     "gaps": [ "state-management", "real-time systems" ],
//     "target_role": "Flutter Developer",
//     "language": "en"
//   }
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function jsonResp(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...CORS, 'Content-Type': 'application/json' },
  });
}

function str(value: unknown): string {
  return value == null ? '' : String(value).trim();
}

function clampStrings(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.map((s: unknown) => String(s).trim()).filter(Boolean).slice(0, 30);
}

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
      return jsonResp({ error: 'Unauthorized' }, 401);
    }

    const groqKey = Deno.env.get('GROQ_API_KEY');
    if (!groqKey) {
      return jsonResp({ error: 'AI is not configured.' }, 503);
    }

    let body: Record<string, unknown>;
    try {
      body = await req.json();
    } catch {
      return jsonResp({ error: 'Invalid JSON body' }, 400);
    }

    const dna = (body.dna ?? {}) as Record<string, unknown>;
    const gaps: string[] = clampStrings(body.gaps);
    const targetRole = str(body.target_role);
    const language = str(body.language) || 'en';

    console.log('[ai_enhance] START gaps:', gaps.length, 'role:', targetRole, 'groqKey:', groqKey ? 'present' : 'MISSING');

    if (gaps.length === 0) {
      console.log('[ai_enhance] no gaps, returning empty');
      return jsonResp({ suggestions: [] });
    }

    const skills = clampStrings(dna.skills);
    const profile = (dna.profile ?? {}) as Record<string, unknown>;
    const summary = str(profile.summary);

    const experienceList = Array.isArray(profile.experience)
      ? (profile.experience as Array<Record<string, unknown>>)
      : [];
    const experienceStr = experienceList
      .map((e) => `${str(e.role)} at ${str(e.company)}: ${str(e.description).slice(0, 200)}`)
      .filter((s) => s.length > 5)
      .join(' | ');

    const projectsList = Array.isArray(profile.projects)
      ? (profile.projects as Array<Record<string, unknown>>)
      : [];
    const projectsStr = projectsList
      .map((p) => `${str(p.name)}: ${str(p.description).slice(0, 200)} [${clampStrings(p.tech).join(', ')}]`)
      .filter((s) => s.length > 5)
      .join(' | ');

    const prompt = `You are an aggressive ATS optimization expert. Your job is to MAXIMIZE the match score by closing EVERY gap.

The user is targeting: ${targetRole || 'a software engineering role'}.

ALL gaps that must be addressed (${gaps.length} total):
${gaps.map((g) => `- ${g}`).join('\n')}

Current CareerDNA:
- Skills: ${skills.join(', ') || 'none'}
- Summary: ${summary || 'none'}
- Experience: ${experienceStr || 'none'}
- Projects: ${projectsStr || 'none'}

Your task: generate suggestions to close EVERY gap above. Be aggressive and thorough.

Return ONLY a valid JSON object with a "suggestions" array. No markdown, no explanation, just JSON.
Each suggestion must have:
- "section": one of "skills", "summary", "experience", "projects"
- "action": one of "add", "enhance", "rewrite"
- "itemId": (for experience/projects) the string index of the item to update, or null for new items
- "field": (for experience) which field to update: "bullets", "technologies", "description"
- "current": the current value (string)
- "suggested": the improved value (string)
- "reason": why this change helps close the gap (string)

AGGRESSIVE RULES:
1. For EVERY gap skill: add it as a SEPARATE suggestion with the EXACT gap label as the suggested value. Use the gap label verbatim — e.g. if gap is "state-management", suggested must be "state-management". Do NOT skip any gap.
2. For experience: rewrite bullet points to naturally incorporate 3-5 gap keywords each. Every bullet should be packed with relevant technologies.
3. For projects: rewrite descriptions to mention gap technologies. Add technologies to the tech stack.
4. For summary: rewrite to include at least 5 gap keywords naturally.
5. Each suggestion should address ONE gap specifically. More suggestions = better score.
6. Do NOT fabricate experience the user doesn't have — but DO reframe what they have to match gaps.
7. Respond in ${language === 'ar' ? 'Arabic' : 'English'}.
8. Return ALL suggestions needed — minimum ${gaps.length} suggestions, up to 25.
9. Return valid JSON only, starting with { and ending with }.`;

    const ai = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${groqKey}`,
      },
      body: JSON.stringify({
        model: 'openai/gpt-oss-120b',
        temperature: 0.3,
        max_tokens: 4000,
        response_format: { type: 'json_object' },
        messages: [{ role: 'user', content: prompt }],
      }),
    });

    if (!ai.ok) {
      const detail = await ai.text();
      console.error('[ai_enhance] groq error', ai.status, detail.slice(0, 500));
      return jsonResp({ error: `AI request failed (${ai.status})` }, 502);
    }

    const aiData = await ai.json();
    const content = aiData?.choices?.[0]?.message?.content ?? '{}';
    console.log('[ai_enhance] response length:', content.length);

    let parsed: Record<string, unknown>;
    try {
      parsed = JSON.parse(content);
    } catch {
      // Try to extract JSON from markdown code blocks
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        try {
          parsed = JSON.parse(jsonMatch[0]);
        } catch (e) {
          console.error('[ai_enhance] parse error:', String(e));
          return jsonResp({ error: 'AI returned malformed output' }, 502);
        }
      } else {
        console.error('[ai_enhance] no JSON found in:', content.slice(0, 200));
        return jsonResp({ error: 'AI returned malformed output' }, 502);
      }
    }

    const rawSuggestions = Array.isArray(parsed.suggestions) ? parsed.suggestions : [];
    const suggestions = rawSuggestions.slice(0, 25).map((s: Record<string, unknown>) => ({
      section: str(s.section) || 'skills',
      action: str(s.action) || 'add',
      itemId: s.itemId ?? null,
      field: str(s.field) || null,
      current: str(s.current),
      suggested: str(s.suggested),
      reason: str(s.reason),
    }));

    console.log('[ai_enhance] suggestions count:', suggestions.length);
    return jsonResp({ suggestions });
  } catch (err) {
    console.error('[ai_enhance] unhandled:', String(err));
    return jsonResp({ error: String(err) }, 500);
  }
});
