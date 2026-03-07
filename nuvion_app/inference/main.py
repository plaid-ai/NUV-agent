import os

from nuvion_app.config import load_env
from nuvion_app.runtime.bootstrap import ensure_ready
from nuvion_app.runtime.gstreamer_env import ensure_gstreamer_runtime
from nuvion_app.runtime.inference_mode import apply_inference_runtime_defaults
from nuvion_app.runtime.triton_manager import cleanup_managed_triton
from nuvion_app.inference.webrtc_signaling import UPLINK_MODE_WEBRTC, normalize_uplink_mode


def main():
    load_env()
    apply_inference_runtime_defaults()
    ensure_ready(stage="run")
    ensure_gstreamer_runtime(
        require_webrtc=normalize_uplink_mode(os.getenv("NUVION_UPLINK_MODE")) == UPLINK_MODE_WEBRTC
    )
    from nuvion_app.inference.pipeline import GStreamerInferenceApp

    video_source = os.getenv("NUVION_VIDEO_SOURCE", "/dev/video0")
    app = GStreamerInferenceApp(video_source)
    try:
        app.run()
    finally:
        cleanup_managed_triton(reason="agent_exit")


if __name__ == "__main__":
    main()
