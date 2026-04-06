#!/usr/bin/env node
/**
 * Dev proxy for Instant-Help / PrivacyGUI development.
 *
 * Eliminates the need for CORS-disabled Chrome by proxying everything
 * through a single origin:
 *
 *   Browser → localhost:3000
 *     /JNAP/*  → router at 192.168.1.1 (or ROUTER_IP env var)
 *     /*       → Flutter dev server at localhost:8080 (or FLUTTER_PORT env var)
 *
 * Usage:
 *   # Terminal 1: Start Flutter dev server
 *   cd ~/Projects/PrivacyGUI
 *   ~/.pub-cache/bin/fvm flutter run -d web-server --web-port 8080
 *
 *   # Terminal 2: Start this proxy
 *   node dev-proxy.mjs
 *
 *   # Terminal 3 (or same browser): Open normal Chrome
 *   open http://localhost:3000/#/troubleshoot
 */

import http from 'node:http';
import https from 'node:https';
import fs from 'node:fs';

const PROXY_PORT = parseInt(process.env.PROXY_PORT || '3000');
const HTTPS_PORT = parseInt(process.env.HTTPS_PORT || '3443');
const FLUTTER_PORT = parseInt(process.env.FLUTTER_PORT || '8080');
const ROUTER_IP = process.env.ROUTER_IP || '192.168.1.1';

// Paths that should be forwarded to the router
const ROUTER_PATHS = ['/JNAP/', '/JNAP'];

function proxyToRouter(clientReq, clientRes) {
  const options = {
    hostname: ROUTER_IP,
    port: 80,
    path: clientReq.url,
    method: clientReq.method,
    headers: {
      ...clientReq.headers,
      host: ROUTER_IP,
    },
    // Don't reject self-signed certs
    rejectUnauthorized: false,
  };

  // Remove origin/referer that would confuse the router
  delete options.headers['origin'];
  delete options.headers['referer'];

  const proxy = http.request(options, (routerRes) => {
    // Add CORS headers so the browser is happy
    const headers = { ...routerRes.headers };
    headers['access-control-allow-origin'] = '*';
    headers['access-control-allow-methods'] = 'GET, POST, PUT, DELETE, OPTIONS';
    headers['access-control-allow-headers'] = '*';

    clientRes.writeHead(routerRes.statusCode, headers);
    routerRes.pipe(clientRes);
  });

  proxy.on('error', (err) => {
    console.error(`[router] ${err.message}`);
    clientRes.writeHead(502, { 'content-type': 'text/plain' });
    clientRes.end(`Router proxy error: ${err.message}`);
  });

  clientReq.pipe(proxy);
}

function proxyToFlutter(clientReq, clientRes) {
  // Try localhost first (resolves to ::1 on some systems), fall back to 127.0.0.1
  const tryConnect = (hostname) => {
    const options = {
      hostname,
      port: FLUTTER_PORT,
      path: clientReq.url,
      method: clientReq.method,
      headers: {
        ...clientReq.headers,
        host: `${hostname}:${FLUTTER_PORT}`,
      },
    };

    const proxy = http.request(options, (flutterRes) => {
      clientRes.writeHead(flutterRes.statusCode, flutterRes.headers);
      flutterRes.pipe(clientRes);
    });

    proxy.on('error', (err) => {
      if (err.code === 'ECONNREFUSED' && hostname === 'localhost') {
        // localhost (IPv6) failed, try IPv4
        tryConnect('127.0.0.1');
        return;
      }
      console.error(`[flutter] ${err.message}`);
      clientRes.writeHead(502, { 'content-type': 'text/plain' });
      clientRes.end(`Flutter proxy error: ${err.message}\nIs the Flutter dev server running on port ${FLUTTER_PORT}?`);
    });

    clientReq.pipe(proxy);
  };

  tryConnect('localhost');
}

// Shared request handler for both HTTP and HTTPS servers
function handleRequest(req, res) {
  console.log(`[req] ${req.method} ${req.url}`);

  // Handle CORS preflight for JNAP
  if (req.method === 'OPTIONS' && ROUTER_PATHS.some(p => req.url.startsWith(p))) {
    res.writeHead(204, {
      'access-control-allow-origin': '*',
      'access-control-allow-methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'access-control-allow-headers': '*',
      'access-control-max-age': '86400',
    });
    res.end();
    return;
  }

  const isRouterPath = ROUTER_PATHS.some(p => req.url.startsWith(p));

  if (isRouterPath) {
    console.log(`[router] ${req.method} ${req.url}`);
    proxyToRouter(req, res);
  } else {
    proxyToFlutter(req, res);
  }
}

// Shared WebSocket upgrade handler
function handleUpgrade(req, socket, head) {
  const options = {
    hostname: 'localhost',
    port: FLUTTER_PORT,
    path: req.url,
    method: req.method,
    headers: {
      ...req.headers,
      host: `localhost:${FLUTTER_PORT}`,
    },
  };

  const proxy = http.request(options);

  proxy.on('upgrade', (proxyRes, proxySocket, proxyHead) => {
    socket.write(
      `HTTP/1.1 101 Switching Protocols\r\n` +
      Object.entries(proxyRes.headers).map(([k, v]) => `${k}: ${v}`).join('\r\n') +
      '\r\n\r\n'
    );
    if (proxyHead.length) socket.write(proxyHead);
    proxySocket.pipe(socket);
    socket.pipe(proxySocket);
  });

  proxy.on('error', (err) => {
    console.error(`[ws] ${err.message}`);
    socket.end();
  });

  proxy.end();
}

const server = http.createServer(handleRequest);
server.on('upgrade', handleUpgrade);

server.listen(PROXY_PORT, () => {
  console.log(`  HTTP proxy listening on http://localhost:${PROXY_PORT}`);
});

// HTTPS server (PrivacyGUI force=local builds JNAP URLs as https://<host>/JNAP/)
try {
  const sslOpts = {
    key: fs.readFileSync('/tmp/proxy-key.pem'),
    cert: fs.readFileSync('/tmp/proxy-cert.pem'),
  };
  const httpsServer = https.createServer(sslOpts, handleRequest);
  httpsServer.on('upgrade', handleUpgrade);
  httpsServer.listen(HTTPS_PORT, () => {
    console.log(`  HTTPS proxy listening on https://localhost:${HTTPS_PORT}`);
  });
} catch (e) {
  console.log(`  HTTPS disabled (no certs): ${e.message}`);
}

console.log(`
  Instant-Help Dev Proxy
  ────────────────────────────────────────
  HTTP:     http://localhost:${PROXY_PORT}
  HTTPS:    https://localhost:${HTTPS_PORT}
  Flutter:  http://localhost:${FLUTTER_PORT}  (must be running)
  Router:   http://${ROUTER_IP}
  ────────────────────────────────────────
  /JNAP/*  → router (${ROUTER_IP})
  /*       → Flutter dev server

  PrivacyGUI uses https:// for JNAP calls (force=local).
  Open https://localhost:${HTTPS_PORT}/#/troubleshoot in Chrome.
  Accept the self-signed cert warning, then login works.
`);
