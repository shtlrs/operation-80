export async function onRequestGet({ env }) {
  const version = await env.STATE.get('app-version');
  return new Response(version || '', {
    headers: { 'Content-Type': 'text/plain', 'Access-Control-Allow-Origin': '*' }
  });
}
