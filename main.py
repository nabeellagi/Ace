import os
import sys
import time
import threading
from http.server import HTTPServer, BaseHTTPRequestHandler

# # ✅ Patch Plotly validator BEFORE importing Streamlit
# import plotly.validator_cache

# validator_path = os.path.join(os.path.dirname(__file__), 'helper', '_validators.json')
# with open(validator_path, 'r', encoding='utf-8') as f:
#     validator_data = json.load(f)

# plotly.validator_cache.get_validator = lambda path: validator_data.get(path)
# print("[✔] Patched plotly.validator_cache manually.")

# ✅ Monkey-patch Streamlit version
import importlib.metadata as importlib_metadata
_real_version = importlib_metadata.version
importlib_metadata.version = lambda dist: "1.46.0" if dist == "streamlit" else _real_version(dist)

# ✅ Secret path
SECRET_PATH = "/9e7de3"

# ✅ Shutdown Server (same)
def delayed_exit():
    time.sleep(0.5)
    os._exit(0)

class ShutdownHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/shutdown":
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"Shutting down Streamlit...")
            print("🛑 Shutdown request received.")
            threading.Thread(target=delayed_exit, daemon=True).start()
        else:
            self.send_response(404)
            self.end_headers()


def start_shutdown_server():
    server = HTTPServer(("127.0.0.1", 9999), ShutdownHandler)
    print("🛎️  Listening for shutdown command at http://localhost:9999/shutdown")
    server.serve_forever()

# ✅ Start shutdown listener in background
threading.Thread(target=start_shutdown_server, daemon=True).start()

# ✅ Launch Streamlit directly
import streamlit.web.cli as cli

# Set proper Streamlit context
os.environ["STREAMLIT_SERVER_FILE_WATCHER_TYPE"] = "none"
os.environ["STREAMLIT_GLOBAL_DEVELOPMENT_MODE"] = "false"  # <- Fixes the error

# Use appropriate path depending on whether frozen or not
if getattr(sys, 'frozen', False):
    app_path = os.path.join(os.path.dirname(sys.executable), "_internal", "app.py")
else:
    app_path = os.path.join(os.path.dirname(__file__), "app.py")

print(f"[DEBUG] app.py path: {app_path}")
print(f"[DEBUG] Exists: {os.path.exists(app_path)}")

sys.argv = [
    "streamlit", "run", app_path,
    "--server.headless=true",
    "--server.port=8501",
    "--server.address=127.0.0.1",
    "--server.baseUrlPath=9e7de3"
]

cli.main()
