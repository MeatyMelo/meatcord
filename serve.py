"""Local dev server for Meatcord.

Plain `python -m http.server` answers with Last-Modified and lets the browser
cache the page, so after editing meatcord.html the browser can keep running the
OLD file with no visible sign that it is doing so. That is a genuinely nasty
failure mode here: you change a setting, reload, and measure stale behaviour.

This is the same static server with caching turned off.
"""
import http.server
import os
import socketserver
import sys


class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()

    def send_head(self):
        # Ignore conditional requests entirely so the browser can never be told
        # "304 Not Modified" and reuse a stale copy.
        # self.headers is an email.message.Message: it has __delitem__ (a no-op
        # when the field is absent) but no .pop(), which raises AttributeError.
        del self.headers["If-Modified-Since"]
        del self.headers["If-None-Match"]
        return super().send_head()

    def log_message(self, fmt, *args):
        # Keep the console readable; one line per request is just noise here.
        pass


def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8000
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("127.0.0.1", port), NoCacheHandler) as httpd:
        print("Meatcord serving at http://localhost:%d/meatcord.html" % port)
        print("Caching is disabled - edits show up on a normal reload.")
        print("Close this window to stop the server.")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            pass


if __name__ == "__main__":
    main()
