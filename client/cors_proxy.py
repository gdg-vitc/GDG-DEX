#!/usr/bin/env python3
"""
Lightweight local CORS proxy for Flutter Web development.
Forwards all requests to https://gdg-dex.onrender.com
and injects CORS headers so any web browser can connect without CORS issues.

Usage:
  python3 cors_proxy.py
  (Runs on http://localhost:8080 by default)

Then run Flutter Web pointing to the proxy:
  flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
"""

import sys
from http.server import HTTPServer, BaseHTTPRequestHandler
import urllib.request
import urllib.error

TARGET_URL = "https://gdg-dex.onrender.com"
PORT = 8080

class CorsProxyHandler(BaseHTTPRequestHandler):
    def _send_cors_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS, PATCH')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization, ngrok-skip-browser-warning, Accept, X-Requested-With')
        self.send_header('Access-Control-Max-Age', '86400')

    def do_OPTIONS(self):
        self.send_response(200)
        self._send_cors_headers()
        self.end_headers()

    def do_GET(self):
        self._forward_request('GET')

    def do_POST(self):
        self._forward_request('POST')

    def do_PUT(self):
        self._forward_request('PUT')

    def do_DELETE(self):
        self._forward_request('DELETE')

    def do_PATCH(self):
        self._forward_request('PATCH')

    def _forward_request(self, method):
        target_path = self.path
        target_url = f"{TARGET_URL}{target_path}"

        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length) if content_length > 0 else None

        req = urllib.request.Request(target_url, data=body, method=method)
        req.add_header('ngrok-skip-browser-warning', 'true')
        req.add_header('Accept', 'application/json')
        if body and self.headers.get('Content-Type'):
            req.add_header('Content-Type', self.headers.get('Content-Type'))
        if self.headers.get('Authorization'):
            req.add_header('Authorization', self.headers.get('Authorization'))

        try:
            with urllib.request.urlopen(req) as resp:
                status = resp.status
                resp_headers = resp.headers
                content = resp.read()
        except urllib.error.HTTPError as e:
            status = e.code
            resp_headers = e.headers
            content = e.read()
        except Exception as e:
            self.send_response(502)
            self._send_cors_headers()
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(f'{{"error": "Proxy error: {e}"}}'.encode('utf-8'))
            return

        self.send_response(status)
        self._send_cors_headers()
        content_type = resp_headers.get('Content-Type', 'application/json')
        self.send_header('Content-Type', content_type)
        self.end_headers()
        self.wfile.write(content)

    def log_message(self, format, *args):
        sys.stderr.write(f"[CORS Proxy] {self.command} {self.path} -> {args[1] if len(args) > 1 else ''}\n")

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else PORT
    server = HTTPServer(('0.0.0.0', port), CorsProxyHandler)
    print(f"🚀 CORS Development Proxy running at http://localhost:{port}")
    print(f"👉 Forwarding to: {TARGET_URL}")
    print("👉 To run Flutter Web with this proxy:")
    print(f"   flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:{port}\n")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping CORS proxy...")
