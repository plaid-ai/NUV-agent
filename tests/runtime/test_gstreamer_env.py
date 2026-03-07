from __future__ import annotations

import os
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from nuvion_app.runtime import gstreamer_env


class GStreamerEnvTest(unittest.TestCase):
    def test_configure_gstreamer_environment_populates_homebrew_paths_on_macos(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            prefix = Path(tmp)
            (prefix / "lib" / "girepository-1.0").mkdir(parents=True)
            (prefix / "lib" / "gstreamer-1.0").mkdir(parents=True)
            scanner = prefix / "opt" / "gstreamer" / "libexec" / "gstreamer-1.0" / "gst-plugin-scanner"
            scanner.parent.mkdir(parents=True)
            scanner.write_text("#!/bin/sh\n")
            scanner.chmod(0o755)

            with mock.patch.object(gstreamer_env.sys, "platform", "darwin"):
                with mock.patch.object(gstreamer_env, "_candidate_prefixes", return_value=[prefix]):
                    with mock.patch.dict(os.environ, {"NUVION_GSTREAMER_PREFIX": str(prefix)}, clear=True):
                        changes = gstreamer_env.configure_gstreamer_environment()

                        self.assertEqual(
                            os.environ["DYLD_FALLBACK_LIBRARY_PATH"],
                            str(prefix / "lib"),
                        )
                        self.assertEqual(
                            os.environ["GI_TYPELIB_PATH"],
                            str(prefix / "lib" / "girepository-1.0"),
                        )
                        self.assertEqual(
                            os.environ["GST_PLUGIN_PATH"],
                            str(prefix / "lib" / "gstreamer-1.0"),
                        )
                        self.assertEqual(os.environ["GST_PLUGIN_SCANNER"], str(scanner))
                        self.assertIn("GST_PLUGIN_SCANNER", changes)

    def test_configure_gstreamer_environment_preserves_existing_paths(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            prefix = Path(tmp)
            (prefix / "lib" / "girepository-1.0").mkdir(parents=True)
            (prefix / "lib" / "gstreamer-1.0").mkdir(parents=True)

            with mock.patch.object(gstreamer_env.sys, "platform", "darwin"):
                with mock.patch.object(gstreamer_env, "_candidate_prefixes", return_value=[prefix]):
                    with mock.patch.dict(
                        os.environ,
                        {
                            "NUVION_GSTREAMER_PREFIX": str(prefix),
                            "GI_TYPELIB_PATH": "/existing/typelibs",
                            "DYLD_FALLBACK_LIBRARY_PATH": "/existing/lib",
                        },
                        clear=True,
                    ):
                        gstreamer_env.configure_gstreamer_environment()

                        self.assertEqual(
                            os.environ["GI_TYPELIB_PATH"],
                            f"{prefix / 'lib' / 'girepository-1.0'}:/existing/typelibs",
                        )
                        self.assertEqual(
                            os.environ["DYLD_FALLBACK_LIBRARY_PATH"],
                            f"{prefix / 'lib'}:/existing/lib",
                        )

    def test_configure_gstreamer_environment_noops_off_macos(self) -> None:
        with mock.patch.object(gstreamer_env.sys, "platform", "linux"):
            with mock.patch.dict(os.environ, {}, clear=True):
                changes = gstreamer_env.configure_gstreamer_environment()
                self.assertEqual(changes, {})
                self.assertNotIn("GI_TYPELIB_PATH", os.environ)


if __name__ == "__main__":
    unittest.main()
