const server = Bun.serve({
  port: process.env.PORT || 3000,
  fetch(req) {
    const url = new URL(req.url);
    if (url.pathname === '/api/health') {
      return new Response(JSON.stringify({ status: 'ok' }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }
    return new Response('Hello from devops-final\n');
  },
});

console.log(`Server running on port ${server.port}`);
