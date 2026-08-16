// Cloudflare Pages Function — handles GET and POST for tracker state.
// Bound KV namespace: STATE (set in wrangler.toml / Pages dashboard)

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

export async function onRequestOptions() {
  return new Response(null, { headers: CORS });
}

export async function onRequestGet({ env }) {
  const state = await env.STATE.get('tracker', { type: 'json' });
  return Response.json(state || {}, { headers: CORS });
}

export async function onRequestPost({ request, env }) {
  let body;
  try {
    body = await request.json();
  } catch {
    return new Response('Invalid JSON', { status: 400, headers: CORS });
  }
  await env.STATE.put('tracker', JSON.stringify(body));
  return new Response('ok', { headers: CORS });
}
