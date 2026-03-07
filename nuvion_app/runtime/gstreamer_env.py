from __future__ import annotations

import os
import shutil
import sys
from pathlib import Path


def _split_env_paths(value: str) -> list[str]:
    return [item for item in value.split(os.pathsep) if item]


def _prepend_env_paths(key: str, paths: list[str]) -> str | None:
    existing = os.environ.get(key, "")
    merged: list[str] = []

    for path in paths + _split_env_paths(existing):
        if not path or path in merged:
            continue
        merged.append(path)

    if not merged:
        return None

    new_value = os.pathsep.join(merged)
    if new_value != existing:
        os.environ[key] = new_value
        return new_value
    return None


def _candidate_prefixes() -> list[Path]:
    candidates: list[Path] = []
    raw = os.getenv("NUVION_GSTREAMER_PREFIX", "").strip()
    for candidate in raw.split(os.pathsep) if raw else []:
        path = Path(candidate).expanduser()
        if path.exists() and path not in candidates:
            candidates.append(path)

    for candidate in ("/opt/homebrew", "/usr/local"):
        path = Path(candidate)
        if path.exists() and path not in candidates:
            candidates.append(path)
    return candidates


def _find_plugin_scanner(prefixes: list[Path]) -> str | None:
    scanner = os.environ.get("GST_PLUGIN_SCANNER", "").strip()
    if scanner and Path(scanner).exists():
        return scanner

    which_scanner = shutil.which("gst-plugin-scanner")
    if which_scanner:
        return which_scanner

    for prefix in prefixes:
        for candidate in (
            prefix / "opt" / "gstreamer" / "libexec" / "gstreamer-1.0" / "gst-plugin-scanner",
            prefix / "libexec" / "gstreamer-1.0" / "gst-plugin-scanner",
        ):
            if candidate.exists():
                return str(candidate)
    return None


def _candidate_plugin_paths(prefixes: list[Path]) -> list[str]:
    paths: list[str] = []
    for prefix in prefixes:
        for candidate in (
            prefix / "lib" / "gstreamer-1.0",
            prefix / "opt" / "gstreamer" / "lib" / "gstreamer-1.0",
            prefix / "opt" / "libnice-gstreamer" / "libexec" / "gstreamer-1.0",
        ):
            if candidate.exists():
                paths.append(str(candidate))
    return paths


def configure_gstreamer_environment() -> dict[str, str]:
    changes: dict[str, str] = {}
    if sys.platform != "darwin":
        return changes

    prefixes = _candidate_prefixes()
    lib_paths: list[str] = []
    typelib_paths: list[str] = []
    plugin_paths = _candidate_plugin_paths(prefixes)

    for prefix in prefixes:
        lib_dir = prefix / "lib"
        if lib_dir.exists():
            lib_paths.append(str(lib_dir))

        typelib_dir = lib_dir / "girepository-1.0"
        if typelib_dir.exists():
            typelib_paths.append(str(typelib_dir))

    for key, paths in (
        ("DYLD_FALLBACK_LIBRARY_PATH", lib_paths),
        ("GI_TYPELIB_PATH", typelib_paths),
        ("GST_PLUGIN_PATH", plugin_paths),
    ):
        updated = _prepend_env_paths(key, paths)
        if updated:
            changes[key] = updated

    scanner = _find_plugin_scanner(prefixes)
    if scanner and os.environ.get("GST_PLUGIN_SCANNER") != scanner:
        os.environ["GST_PLUGIN_SCANNER"] = scanner
        changes["GST_PLUGIN_SCANNER"] = scanner

    return changes


def ensure_gstreamer_runtime(*, require_webrtc: bool) -> None:
    configure_gstreamer_environment()

    try:
        import gi

        gi.require_version("Gst", "1.0")
        from gi.repository import Gst
    except Exception as exc:  # pragma: no cover - exercised by runtime validation
        raise RuntimeError(
            "GStreamer bindings are unavailable. "
            "On macOS, ensure Homebrew gstreamer/glib typelibs and libraries are visible to the process."
        ) from exc

    Gst.init(None)

    if require_webrtc:
        missing_elements: list[str] = []
        for element_name in ("webrtcbin", "nicesrc"):
            if Gst.ElementFactory.find(element_name) is None:
                missing_elements.append(element_name)
        if missing_elements:
            raise RuntimeError(
                "GStreamer WebRTC support is unavailable. "
                f"Missing elements: {', '.join(missing_elements)}. "
                "On Homebrew/macOS, install both 'gstreamer' and 'libnice-gstreamer', then ensure "
                "GI_TYPELIB_PATH, GST_PLUGIN_PATH, and DYLD_FALLBACK_LIBRARY_PATH include the Homebrew prefix."
            )
