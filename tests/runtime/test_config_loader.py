from __future__ import annotations

import os
import tempfile
import unittest
from pathlib import Path

from nuvion_app import config as config_module


class ConfigLoaderTest(unittest.TestCase):
    def setUp(self) -> None:
        config_module._LOADED = False
        config_module._LOADED_PATH = None
        for key in ("NUV_AGENT_CONFIG", "NUVION_DEVICE_USERNAME"):
            os.environ.pop(key, None)

    def test_load_env_reloads_when_config_path_changes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path1 = Path(tmp) / "one.env"
            path2 = Path(tmp) / "two.env"
            path1.write_text("NUVION_DEVICE_USERNAME=device-one\n")
            path2.write_text("NUVION_DEVICE_USERNAME=device-two\n")

            config_module.load_env(str(path1))
            self.assertEqual(os.getenv("NUVION_DEVICE_USERNAME"), "device-one")

            config_module.load_env(str(path2))
            self.assertEqual(os.getenv("NUVION_DEVICE_USERNAME"), "device-two")


if __name__ == "__main__":
    unittest.main()
