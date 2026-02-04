from __future__ import annotations

import html
import os
import sys
import threading
import urllib.parse
import webbrowser
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from dotenv import dotenv_values, load_dotenv


DEFAULT_PORT = 8088
SECRET_KEY_MARKERS = ("PASSWORD",)
REQUIRED_KEYS = {
    "NUVION_SERVER_BASE_URL",
    "NUVION_DEVICE_USERNAME",
    "NUVION_DEVICE_PASSWORD",
    "NUVION_RTP_REMOTE_IP",
}
PLACEHOLDER_VALUES = {"***"}

_LOADED = False


def _is_placeholder(value: Optional[str]) -> bool:
    if value is None:
        return True
    stripped = value.strip()
    if not stripped:
        return True
    if stripped in PLACEHOLDER_VALUES:
        return True
    if stripped.startswith("<") and stripped.endswith(">"):
        return True
    return False


def _is_secret_key(key: str) -> bool:
    return any(marker in key for marker in SECRET_KEY_MARKERS)


def template_path() -> Path:
    path = Path(__file__).resolve().parent / "config_template.env"
    if path.exists():
        return path
    fallback = Path(__file__).resolve().parents[1] / ".env.example"
    return fallback


def load_template() -> Tuple[List[str], List[Dict[str, str]]]:
    lines = template_path().read_text().splitlines()
    fields: List[Dict[str, str]] = []
    pending_comment: Optional[str] = None
    for line in lines:
        stripped = line.strip()
        if not stripped:
            pending_comment = None
            continue
        if stripped.startswith("#"):
            pending_comment = stripped.lstrip("#").strip()
            continue
        if "=" not in line:
            pending_comment = None
            continue
        key, default = line.split("=", 1)
        fields.append(
            {
                "key": key.strip(),
                "default": default.strip(),
                "comment": pending_comment or "",
            }
        )
        pending_comment = None
    return lines, fields


def _find_repo_env(start: Path) -> Optional[Path]:
    for parent in [start, *start.parents]:
        if (parent / ".env").exists() and (parent / "nuvion_app").is_dir():
            return parent / ".env"
    return None


def _default_system_paths() -> List[Path]:
    if sys.platform == "darwin":
        paths: List[Path] = []
        opt_homebrew = Path("/opt/homebrew/etc/nuv-agent/agent.env")
        usr_local = Path("/usr/local/etc/nuv-agent/agent.env")
        if opt_homebrew.exists() or Path("/opt/homebrew").exists():
            paths.append(opt_homebrew)
            paths.append(usr_local)
        else:
            paths.append(usr_local)
            paths.append(opt_homebrew)
        paths.append(Path("/etc/nuv-agent/agent.env"))
        return paths
    return [Path("/etc/nuv-agent/agent.env")]


def resolve_config_path(explicit: Optional[str] = None) -> Path:
    if explicit:
        return Path(explicit).expanduser()
    env_path = os.getenv("NUV_AGENT_CONFIG")
    if env_path:
        return Path(env_path).expanduser()

    repo_env = _find_repo_env(Path.cwd())
    if repo_env:
        return repo_env

    candidates = _default_system_paths()
    for path in candidates:
        if path.exists():
            return path
    return candidates[0]


def load_env(path: Optional[str] = None) -> Path:
    global _LOADED
    if _LOADED:
        return resolve_config_path(path)
    config_path = resolve_config_path(path)
    os.environ.setdefault("NUV_AGENT_CONFIG", str(config_path))
    load_dotenv(config_path, override=False)
    _LOADED = True
    return config_path


def read_env(path: Path) -> Dict[str, str]:
    if not path.exists():
        return {}
    values = dotenv_values(path)
    return {key: value for key, value in values.items() if value is not None}


def render_env(lines: List[str], values: Dict[str, str]) -> str:
    rendered: List[str] = []
    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or "=" not in line:
            rendered.append(line)
            continue
        key = line.split("=", 1)[0].strip()
        value = values.get(key, "")
        rendered.append(f"{key}={value}")
    return "\n".join(rendered) + "\n"


def write_env(path: Path, lines: List[str], values: Dict[str, str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    content = render_env(lines, values)
    path.write_text(content)


def _merge_defaults(fields: List[Dict[str, str]], existing: Dict[str, str]) -> Dict[str, str]:
    merged: Dict[str, str] = dict(existing)
    for field in fields:
        key = field["key"]
        if key not in merged:
            merged[key] = field["default"]
    return merged


def _validate_required(values: Dict[str, str]) -> List[str]:
    missing = []
    for key in REQUIRED_KEYS:
        if _is_placeholder(values.get(key)):
            missing.append(key)
    return missing


def prompt_cli(fields: List[Dict[str, str]], existing: Dict[str, str], advanced: bool) -> Dict[str, str]:
    values = _merge_defaults(fields, existing)
    for field in fields:
        key = field["key"]
        default = values.get(key, "")
        required = key in REQUIRED_KEYS
        if not advanced and not required:
            continue

        label = field["comment"] or key
        prompt = f"{label} ({key})"
        if default:
            prompt += f" [{default}]"
        prompt += ": "

        while True:
            if _is_secret_key(key):
                import getpass

                entered = getpass.getpass(prompt)
            else:
                entered = input(prompt)

            if not entered:
                entered = default
            values[key] = entered

            if required and _is_placeholder(values.get(key)):
                print("A value is required.")
                continue
            break

    return values


def _has_display() -> bool:
    if sys.platform == "darwin":
        return True
    return bool(os.getenv("DISPLAY") or os.getenv("WAYLAND_DISPLAY"))


def _render_form(fields: List[Dict[str, str]], values: Dict[str, str], missing: List[str]) -> str:
    rows: List[str] = []
    for field in fields:
        key = field["key"]
        comment = field["comment"] or key
        value = values.get(key, field["default"])
        is_secret = _is_secret_key(key)
        input_type = "password" if is_secret else "text"
        placeholder = ""
        note = ""
        if is_secret and values.get(key):
            value = ""
            note = "<div class=\"note\">Leave blank to keep current value.</div>"
        required_attr = "required" if (key in REQUIRED_KEYS and _is_placeholder(values.get(key))) else ""
        if key in missing:
            placeholder = " required"
        rows.append(
            """
            <div class="field">
              <label>{label}<span class="key">{key}</span></label>
              <input type="{input_type}" name="{key}" value="{value}" {required} placeholder="{placeholder}">
              {note}
            </div>
            """.format(
                label=html.escape(comment),
                key=html.escape(key),
                input_type=input_type,
                value=html.escape(value or ""),
                required=required_attr,
                placeholder=html.escape(placeholder.strip()),
                note=note,
            )
        )

    error_block = ""
    if missing:
        error_items = " ".join(html.escape(key) for key in missing)
        error_block = f"<div class=\"error\">Missing required values: {error_items}</div>"

    return """
    <!doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>Nuvion Agent Setup</title>
        <style>
          :root {{
            color-scheme: light;
            --bg: #f6f4f0;
            --card: #ffffff;
            --ink: #1a1a1a;
            --muted: #606060;
            --accent: #2f6b4f;
            --border: #e3ded7;
          }}
          body {{
            margin: 0;
            font-family: "Avenir Next", "Helvetica Neue", Helvetica, Arial, sans-serif;
            background: var(--bg);
            color: var(--ink);
          }}
          .wrap {{
            max-width: 820px;
            margin: 40px auto 80px;
            padding: 0 20px;
          }}
          header h1 {{
            font-size: 28px;
            margin-bottom: 6px;
          }}
          header p {{
            color: var(--muted);
            margin-top: 0;
          }}
          .card {{
            background: var(--card);
            border-radius: 16px;
            padding: 24px;
            box-shadow: 0 12px 30px rgba(0,0,0,0.08);
            border: 1px solid var(--border);
          }}
          .field {{
            display: flex;
            flex-direction: column;
            margin-bottom: 18px;
          }}
          label {{
            font-weight: 600;
            margin-bottom: 6px;
            display: flex;
            justify-content: space-between;
            gap: 12px;
          }}
          .key {{
            font-size: 12px;
            color: var(--muted);
            font-weight: 400;
          }}
          input {{
            padding: 10px 12px;
            border: 1px solid var(--border);
            border-radius: 8px;
            font-size: 14px;
          }}
          .note {{
            font-size: 12px;
            color: var(--muted);
            margin-top: 6px;
          }}
          .actions {{
            display: flex;
            justify-content: flex-end;
            margin-top: 18px;
          }}
          button {{
            background: var(--accent);
            color: white;
            border: none;
            padding: 12px 18px;
            border-radius: 10px;
            font-weight: 600;
            cursor: pointer;
          }}
          .error {{
            background: #ffe3e3;
            color: #8a1f1f;
            padding: 12px 14px;
            border-radius: 8px;
            margin-bottom: 18px;
          }}
        </style>
      </head>
      <body>
        <div class="wrap">
          <header>
            <h1>Nuvion Agent Setup</h1>
            <p>Enter device settings and save.</p>
          </header>
          <div class="card">
            {error_block}
            <form method="post" action="/save">
              {rows}
              <div class="actions">
                <button type="submit">Save</button>
              </div>
            </form>
          </div>
        </div>
      </body>
    </html>
    """.format(error_block=error_block, rows="\n".join(rows))


def run_web_setup(
    config_path: Path,
    host: str,
    port: int,
    open_browser: bool,
) -> None:
    lines, fields = load_template()
    existing = _merge_defaults(fields, read_env(config_path))
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, format: str, *args) -> None:  # noqa: A003
            return

        def _send_html(self, status: HTTPStatus, body: str) -> None:
            payload = body.encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)

        def do_GET(self) -> None:  # noqa: N802
            if self.path in ("/", "/index.html"):
                missing = _validate_required(existing)
                body = _render_form(fields, existing, missing)
                self._send_html(HTTPStatus.OK, body)
                return
            if self.path == "/health":
                self.send_response(HTTPStatus.OK)
                self.send_header("Content-Type", "text/plain")
                self.end_headers()
                self.wfile.write(b"ok")
                return
            self.send_response(HTTPStatus.NOT_FOUND)
            self.end_headers()

        def do_POST(self) -> None:  # noqa: N802
            if self.path != "/save":
                self.send_response(HTTPStatus.NOT_FOUND)
                self.end_headers()
                return
            length = int(self.headers.get("Content-Length", "0"))
            body = self.rfile.read(length).decode("utf-8")
            parsed = urllib.parse.parse_qs(body)
            values = dict(existing)

            for field in fields:
                key = field["key"]
                posted = parsed.get(key, [""])[0].strip()
                if not posted and _is_secret_key(key) and existing.get(key):
                    values[key] = existing[key]
                else:
                    values[key] = posted

            missing = _validate_required(values)
            if missing:
                body = _render_form(fields, values, missing)
                self._send_html(HTTPStatus.BAD_REQUEST, body)
                return

            write_env(config_path, lines, values)
            success = """
            <!doctype html>
            <html lang="en">
              <head>
                <meta charset="utf-8" />
                <title>Saved</title>
              </head>
              <body>
                <h2>Saved</h2>
                <p>Settings saved. Restart the service to apply.</p>
              </body>
            </html>
            """
            self._send_html(HTTPStatus.OK, success)
            threading.Thread(target=self.server.shutdown, daemon=True).start()

    server = ThreadingHTTPServer((host, port), Handler)
    address = f"http://{host}:{server.server_address[1]}"
    print(f"Setup page: {address}")
    if open_browser:
        browser_target = address
        if host == "0.0.0.0":
            browser_target = f"http://127.0.0.1:{server.server_address[1]}"
        try:
            webbrowser.open(browser_target)
        except Exception:
            pass
    try:
        server.serve_forever()
    finally:
        server.server_close()


def setup_config(
    config_path: Optional[str] = None,
    use_web: Optional[bool] = None,
    host: str = "127.0.0.1",
    port: int = DEFAULT_PORT,
    open_browser: bool = True,
    advanced: bool = False,
) -> Path:
    path = resolve_config_path(config_path)

    if use_web is None:
        use_web = _has_display()

    if use_web:
        run_web_setup(path, host=host, port=port, open_browser=open_browser)
    else:
        lines, fields = load_template()
        existing = read_env(path)
        values = prompt_cli(fields, existing, advanced=advanced)
        missing = _validate_required(values)
        if missing:
            missing_str = ", ".join(missing)
            raise RuntimeError(f"Missing required values: {missing_str}")
        write_env(path, lines, values)
        print(f"Saved: {path}")

    return path
