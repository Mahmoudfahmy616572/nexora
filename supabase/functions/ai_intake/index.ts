// AI Conversational Intake — builds CareerDNA from conversation or imports.
//
//   POST /functions/v1/ai_intake
//   Authorization: Bearer <user access token>
//
//   Mode 1 — GitHub Import:
//   { "mode": "github_import", "github_username": "..." }
//
//   Mode 2 — Conversational intake:
//   { "mode": "chat", "history": [{ "q": "...", "a": "..." }], "target_role": "...", "language": "en" }
//
//   Mode 3 — Finalize:
//   { "mode": "finalize", "history": [...], "target_role": "...", "language": "en" }
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

function extractJson(text: string): Record<string, unknown> {
  const t = (text ?? '').trim();
  try {
    return JSON.parse(t) as Record<string, unknown>;
  } catch {
    const start = t.indexOf('{');
    const end = t.lastIndexOf('}');
    if (start >= 0 && end > start) {
      let slice = t.slice(start, end + 1);
      try {
        return JSON.parse(slice) as Record<string, unknown>;
      } catch {
        let fixed = slice;
        const openBrackets = (fixed.match(/\[/g) || []).length;
        const closeBrackets = (fixed.match(/\]/g) || []).length;
        const openBraces = (fixed.match(/{/g) || []).length;
        const closeBraces = (fixed.match(/}/g) || []).length;
        fixed = fixed.replace(/,\s*"[^"]*"\s*:\s*"?[^"\]]*$/, '');
        fixed += ']'.repeat(Math.max(0, openBrackets - closeBrackets));
        fixed += '}'.repeat(Math.max(0, openBraces - closeBraces));
        try {
          return JSON.parse(fixed) as Record<string, unknown>;
        } catch { /* give up */ }
      }
    }
    throw new Error('AI returned malformed output');
  }
}

// ── GitHub API helpers ────────────────────────────────────────────────────

interface GitHubUser {
  login: string;
  name: string | null;
  bio: string | null;
  location: string | null;
  email: string | null;
  public_repos: number;
  followers: number;
  blog: string | null;
  company: string | null;
}

interface GitHubRepo {
  name: string;
  description: string | null;
  language: string | null;
  stargazers_count: number;
  topics: string[];
  html_url: string;
  homepage: string | null;
}

async function fetchGitHubUser(
  username: string,
): Promise<{ user: GitHubUser; repos: GitHubRepo[] }> {
  const headers = { 'User-Agent': 'nexora-app' };

  const [userRes, reposRes] = await Promise.all([
    fetch(`https://api.github.com/users/${encodeURIComponent(username)}`, {
      headers,
    }),
    fetch(
      `https://api.github.com/users/${encodeURIComponent(username)}/repos?per_page=30&sort=updated`,
      { headers },
    ),
  ]);

  if (!userRes.ok) {
    throw new Error(`GitHub user "${username}" not found (${userRes.status})`);
  }

  const user = (await userRes.json()) as GitHubUser;
  const repos = ((await reposRes.json()) as GitHubRepo[]).filter(
    (r) => !r.name.startsWith('.') && r.name !== username,
  );

  return { user, repos };
}

function buildGitHubFacts(
  user: GitHubUser,
  repos: GitHubRepo[],
): string[] {
  const facts: string[] = [];

  if (user.name) facts.push(`- name: ${user.name}`);
  if (user.bio) facts.push(`- bio: ${user.bio}`);
  if (user.location) facts.push(`- location: ${user.location}`);
  if (user.email) facts.push(`- email: ${user.email}`);
  if (user.company) facts.push(`- company: ${user.company}`);
  if (user.blog) facts.push(`- website: ${user.blog}`);

  // Languages from repos
  const langCounts: Record<string, number> = {};
  for (const r of repos) {
    if (r.language) {
      langCounts[r.language] = (langCounts[r.language] || 0) + 1;
    }
  }
  const langs = Object.entries(langCounts)
    .sort((a, b) => b[1] - a[1])
    .map(([l]) => l);
  if (langs.length) facts.push(`- languages: ${langs.join(', ')}`);

  // Top repos as projects
  const topRepos = repos
    .filter((r) => r.description || r.stargazers_count > 0)
    .sort((a, b) => b.stargazers_count - a.stargazers_count)
    .slice(0, 8);

  if (topRepos.length) {
    const repoLines = topRepos.map((r) => {
      const parts = [`${r.name}`];
      if (r.description) parts.push(`— ${r.description.slice(0, 200)}`);
      if (r.language) parts.push(`(${r.language})`);
      if (r.topics?.length) parts.push(`[topics: ${r.topics.join(', ')}]`);
      parts.push(`[url: ${r.html_url}]`);
      if (r.homepage) parts.push(`[homepage: ${r.homepage}]`);
      return parts.join(' ');
    });
    facts.push(`- projects: ${repoLines.join(' | ')}`);
  }

  facts.push(`- github_repos_count: ${user.public_repos}`);
  facts.push(`- github_followers: ${user.followers}`);

  return facts;
}

// ── LLM call ──────────────────────────────────────────────────────────────

async function callLlm(
  prompt: string,
  groqKey: string,
  maxTokens = 3000,
): Promise<Record<string, unknown>> {
  const ai = await fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${groqKey}`,
    },
    body: JSON.stringify({
      model: 'openai/gpt-oss-120b',
      temperature: 0.4,
      max_tokens: maxTokens,
      response_format: { type: 'json_object' },
      messages: [{ role: 'user', content: prompt }],
    }),
  });

  if (!ai.ok) {
    const detail = await ai.text();
    console.error('groq error', ai.status, detail);
    throw new Error('AI request failed');
  }

  const aiData = await ai.json();
  const content = aiData?.choices?.[0]?.message?.content ?? '';
  console.log('LLM raw content:', content.substring(0, 800));
  return extractJson(content);
}

// ── Main serve ────────────────────────────────────────────────────────────

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
    const token = authHeader.replace(/^Bearer\s+/i, '');
    const {
      data: { user },
    } = await supabase.auth.getUser(token);
    if (!user) return json({ error: 'Unauthorized' }, 401);

    const groqKey = Deno.env.get('GROQ_API_KEY');
    if (!groqKey) {
      return json(
        { error: 'AI is not configured. Set the GROQ_API_KEY secret.' },
        503,
      );
    }

    const body = await req.json().catch(() => ({}));
    const mode = str(body.mode) || 'chat';
    const language = str(body.language) || 'en';
    const targetRole = str(body.target_role);
    const history: Array<{ q: string; a: string }> = Array.isArray(body.history)
      ? body.history
      : [];

    // ── Mode: github_import ───────────────────────────────────────────────
    if (mode === 'github_import') {
      const username = str(body.github_username);
      if (!username) {
        return json({ error: 'github_username is required' }, 400);
      }

      let ghUser: GitHubUser;
      let ghRepos: GitHubRepo[];
      try {
        const result = await fetchGitHubUser(username);
        ghUser = result.user;
        ghRepos = result.repos;
      } catch (e) {
        return json({ error: String(e) }, 400);
      }

      const facts = buildGitHubFacts(ghUser, ghRepos);
      const factsText = facts.join('\n');

      const langInstruction =
        language === 'ar'
          ? 'بالعربية. استخرج كل الحقائق من بيانات GitHub وابنِ ملفCareerDNA كامل.'
          : 'in English. Extract all facts from GitHub data and build a complete CareerDNA profile.';

      const prompt = [
        `You are a career profile builder. ${langInstruction}`,
        '',
        'STRICT RULES:',
        '1. ONLY use facts from the GitHub data below. Never invent experience, employment, degrees, or certifications.',
        '2. For experience: if the bio or repos suggest professional work, create entries. Otherwise leave empty.',
        '3. For summary: write a professional summary based ONLY on the bio and project evidence.',
        '4. For skills: extract from repo languages, topics, and technologies visible in descriptions.',
        '5. For projects: use the provided repos as project entries.',
        '6. Infer a reasonable targetRole from the languages, topics, and bio if not provided.',
        '',
        'Return a JSON object:',
        '{',
        '  "name": "",',
        '  "targetRole": "",',
        '  "summary": "",',
        '  "experience": [ { "role": "", "company": "", "durationMonths": 0, "description": "", "bullets": [""], "technologies": [""] } ],',
        '  "projects": [ { "name": "", "description": "", "tech": [""], "links": [ { "label": "GitHub", "url": "" } ] } ],',
        '  "skills": [""],',
        '  "education": [ { "degree": "", "field": "", "institution": "" } ],',
        '  "certifications": [ { "name": "" } ],',
        '  "achievements": [""],',
        '  "languages": [""]',
        '}',
        '',
        'GITHUB DATA:',
        factsText,
        ...(targetRole ? [`TARGET ROLE: ${targetRole}`] : []),
      ].join('\n');

      const parsed = await callLlm(prompt, groqKey, 3000);
      return json({ profile: parsed, source: 'github_import' });
    }

    // ── Mode: chat / finalize ─────────────────────────────────────────────
    if (mode === 'chat' || mode === 'finalize') {
      const isFinalize = mode === 'finalize';
      const historyText = history
        .map((h) => `AI: ${h.q}\nUser: ${h.a}`)
        .join('\n');

      const langInstruction =
        language === 'ar'
          ? 'بالعربية.'
          : 'in English.';

      const contextLines: string[] = [];
      if (targetRole) contextLines.push(`Target role: ${targetRole}`);

      const maxTurns = isFinalize ? 999 : 6;

      const prompt = [
        `You are a friendly career coach. ${langInstruction}`,
        '',
        'RULES:',
        '- Ask ONE question at a time with 5-7 choices.',
        '- Always end choices with { "label": "Other", "value": "other", "type": "other" }.',
        '- For multi-answer questions (skills, tech, projects, platforms), set "type": "multi" on EVERY choice.',
        '- For single-answer questions (role, years, education), set "type": "single".',
        `- After ${maxTurns} turns or when you have enough info, set "done": true and include the full profile.`,
        '',
        'You MUST return ONLY a JSON object. No markdown, no explanation.',
        '',
        'WHEN ASKING A QUESTION, return exactly this format:',
        '{ "done": false, "question": "your question here?", "feedback": "brief encouragement", "choices": [ {"label":"Option 1","value":"opt1"}, {"label":"Option 2","value":"opt2"}, {"label":"Option 3","value":"opt3"}, {"label":"Option 4","value":"opt4"}, {"label":"Option 5","value":"opt5"}, {"label":"Other","value":"other","type":"other"} ] }',
        '',
        'WHEN DONE, return exactly this format:',
        '{ "done": true, "feedback": "Great!", "profile": { "name":"", "targetRole":"", "summary":"", "experience":[{"role":"","company":"","durationMonths":0,"description":"","bullets":[""],"technologies":[""]}], "projects":[{"name":"","description":"","tech":[""],"links":[]}], "skills":[""], "education":[{"degree":"","field":"","institution":""}], "certifications":[{"name":"","link":""}], "achievements":[""], "languages":[""] } }',
        '',
        ...(contextLines.length
          ? ['CONTEXT:', ...contextLines.map((l) => `- ${l}`)]
          : []),
        '',
        ...(historyText
          ? ['CONVERSATION SO FAR:', historyText]
          : [
              'This is the first message. Start by asking about their role with specific choices.',
            ]),
        '',
        isFinalize
          ? 'The user wants to finalize. Produce the complete CareerDNA profile now based on everything discussed.'
          : history.length >= 5
            ? 'You have enough information. Produce the final profile now (set done=true).'
            : 'Ask the single most useful NEXT question with 5-7 tap choices. Be specific and relevant to what was discussed.',
      ].join('\n');

      const parsed = await callLlm(prompt, groqKey, isFinalize ? 4000 : 1500);

      console.log('LLM response:', JSON.stringify(parsed).substring(0, 500));

      // Validate: if question is empty and not done, add fallback
      const question = (parsed.question as string ?? '').trim();
      const done = parsed.done ?? false;
      const choices = Array.isArray(parsed.choices) ? parsed.choices : [];

      if (!done && !question) {
        // LLM returned invalid response — force finalize with whatever profile we have
        return json({
          done: true,
          question: null,
          feedback: null,
          choices: null,
          profile: parsed.profile ?? null,
        });
      }

      // Validate: if choices is empty and not done, add fallback choices
      if (!done && choices.length === 0) {
        choices.push(
          { label: 'Yes', value: 'yes' },
          { label: 'Somewhat', value: 'somewhat' },
          { label: 'Not really', value: 'not_really' },
          { label: 'Other', value: 'other', type: 'other' },
        );
      }

      return json({
        done,
        question: question || null,
        feedback: parsed.feedback ?? null,
        choices: choices.length > 0 ? choices : null,
        profile: parsed.profile ?? done ? parsed : null,
      });
    }

    return json({ error: `Unknown mode: ${mode}` }, 400);
  } catch (err) {
    console.error('ai_intake failed', err);
    return json({ error: String(err) }, 500);
  }
});
