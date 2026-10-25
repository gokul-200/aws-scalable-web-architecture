#!/usr/bin/env python3
"""Tiny web server for the ALB target group (stdlib only).

Routes
  /          the web page (index.html)
  /health    ALB health check, returns 200 "ok"
  /api/info  JSON: which instance answered (instance id, AZ, IP, request count)

Instance details come from the EC2 metadata service (IMDSv2).
"""
import json
import os
import threading
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = int(os.environ.get("PORT", "8000"))
BASE = os.path.dirname(os.path.abspath(__file__))
IMDS = "http://169.254.169.254/latest"

_count = 0
_lock = threading.Lock()


def imds(path):
    """Read a value from IMDSv2. Returns 'unknown' when not running on EC2."""
    try:
        tok_req = urllib.request.Request(
            f"{IMDS}/api/token", method="PUT",
            headers={"X-aws-ec2-metadata-token-ttl-seconds": "300"})
        token = urllib.request.urlopen(tok_req, timeout=2).read().decode()
        req = urllib.request.Request(
            f"{IMDS}/meta-data/{path}", headers={"X-aws-ec2-metadata-token": token})
        return urllib.request.urlopen(req, timeout=2).read().decode()
    except Exception:
        return "unknown"


INFO = {
    "instance_id": imds("instance-id"),
    "availability_zone": imds("placement/availability-zone"),
    "private_ip": imds("local-ipv4"),
    "instance_type": imds("instance-type"),
}


class Handler(BaseHTTPRequestHandler):
    def _send(self, code, body, ctype):
        data = body.encode() if isinstance(body, str) else body
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        global _count
        path = self.path.split("?")[0]
        if path == "/health":
            return self._send(200, "ok", "text/plain")
        with _lock:
            _count += 1
            n = _count
        if path == "/api/info":
            return self._send(200, json.dumps({**INFO, "requests_served": n}),
                              "application/json")
        if path in ("/", "/index.html"):
            with open(os.path.join(BASE, "index.html"), "rb") as f:
                return self._send(200, f.read(), "text/html; charset=utf-8")
        self._send(404, "not found", "text/plain")

    def log_message(self, fmt, *args):  # one line per request -> journald
        print(f"{self.client_address[0]} {fmt % args}", flush=True)


if __name__ == "__main__":
    print(f"serving on 0.0.0.0:{PORT} as {INFO['instance_id']}", flush=True)
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
