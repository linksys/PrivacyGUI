#!/usr/bin/env python3
"""Run real-browser AI session transport tests against a loopback fixture."""

import argparse
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import subprocess
import threading


class SessionFixture(BaseHTTPRequestHandler):
    release = threading.Event()
    held = threading.Event()
    released = threading.Event()

    def log_message(self, *_args):
        pass  # No request bodies, credentials, or cookies in logs.

    def reply(self, data, cookie=None):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', self.headers.get('Origin', ''))
        self.send_header('Access-Control-Allow-Credentials', 'true')
        self.send_header('Access-Control-Allow-Headers', 'content-type,cache-control')
        self.send_header('Content-Type', 'application/json')
        if cookie:
            self.send_header('Set-Cookie', cookie)
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def do_OPTIONS(self):
        self.reply({})

    def do_GET(self):
        if self.path != '/test-state':
            self.send_error(404)
            return
        self.reply({
            'held': self.held.is_set(),
            'released': self.released.is_set(),
            'cookie_present': 'ai-review-cookie=' in self.headers.get('Cookie', ''),
        })

    def do_POST(self):
        if self.path == '/release':
            self.release.set()
            self.reply({})
            return
        if self.path != '/cgi-bin/ai-session.cgi':
            self.send_error(404)
            return
        payload = json.loads(self.rfile.read(int(self.headers.get('Content-Length', 0))))
        if payload['action'] == 'logout':
            self.reply({}, 'ai-review-cookie=; Path=/; HttpOnly; SameSite=Lax; Max-Age=0')
            return
        if payload.get('admin_password') == 'HeldFixture':
            self.held.set()
            if not self.release.wait(15):
                return
            try:
                self.reply({}, 'ai-review-cookie=late; Path=/; HttpOnly; SameSite=Lax')
            except (BrokenPipeError, ConnectionResetError):
                pass  # Expected when BrowserClient aborts the held fetch.
            finally:
                self.released.set()
        elif payload.get('admin_password') == 'ImmediateFixture':
            self.reply({}, 'ai-review-cookie=fresh; Path=/; HttpOnly; SameSite=Lax')
        else:
            self.send_error(400)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--flutter', default='flutter')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    server = ThreadingHTTPServer(('127.0.0.1', 0), SessionFixture)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        return subprocess.run([
            args.flutter, 'test', '--no-pub', '--platform', 'chrome', '--reporter', 'expanded',
            f'--dart-define=AI_SESSION_TEST_ORIGIN=http://localhost:{server.server_port}',
            'test/core/ai_session/ai_session_http_browser_test.dart',
            'test/core/ai_session/ai_session_service_factory_web_test.dart',
        ], cwd=root, timeout=180).returncode
    finally:
        SessionFixture.release.set()
        server.shutdown()
        server.server_close()
        thread.join()


if __name__ == '__main__':
    raise SystemExit(main())
