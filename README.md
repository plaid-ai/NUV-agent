# Nuvion Agent (Device Software)

NUV-agent는 온디바이스 AI 장치에 설치하는 소프트웨어입니다. 도커 기반으로 제작되어 이식이 쉽고,
USB 기반 웹캠 카메라 스트림을 Nuvion-be 스프링 서버를 통해 송출할 수 있습니다. 동시에 제로샷 AI 모델로
이상 감지를 수행하여 공장에서 이상 감지와 생산량 추적을 할 수 있도록 해주는 프로그램입니다. 감지 결과는
영상 위에 실시간으로 오버레이 됩니다.

## Structure
- `nuvion_app/inference`: GStreamer RTP streaming + zero-shot anomaly detection

## Install (brew/apt)
Packaging templates and build scripts live in `packaging/`. See `packaging/README.md`.

Homebrew (Apple Silicon):
```bash
brew tap plaid-ai/NUV-agent-homebrew
brew install nuv-agent
```
Note: Homebrew install includes Zero-shot (torch/transformers/Pillow) deps. The download is large.

APT (Jetson/Ubuntu, arm64):
```bash
sudo install -d /etc/apt/keyrings
curl -fsSL https://apt.plaidai.io/public.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/plaidai.gpg
echo "deb [signed-by=/etc/apt/keyrings/plaidai.gpg arch=arm64] https://apt.plaidai.io stable main" | sudo tee /etc/apt/sources.list.d/plaidai.list
sudo apt update
sudo apt install nuv-agent
```
One-line install:
```bash
curl -fsSL https://apt.plaidai.io/install-apt.sh | bash
```

## Quick start (dev)
1) Copy `.env.example` to `.env` and fill in credentials.
2) Run locally:
   ```bash
   pip install -e .
   python -m nuvion_app.cli run
   ```

Python requirement: 3.10+

## macOS dev setup (Homebrew)
Recommended for local runs on Apple Silicon.
```bash
brew install python@3.14 gobject-introspection pygobject3 gstreamer \
  gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav

/opt/homebrew/opt/python@3.14/bin/python3 -m venv .venv --system-site-packages
source .venv/bin/activate
pip install -e .

export DYLD_LIBRARY_PATH=/opt/homebrew/lib
export GI_TYPELIB_PATH=/opt/homebrew/lib/girepository-1.0
export GST_PLUGIN_PATH=/opt/homebrew/lib/gstreamer-1.0

python -m nuvion_app.cli run
```
Note: `pygobject3` is tied to Homebrew’s Python. Using `python@3.14` and `--system-site-packages`
ensures the `gi` module is visible inside the venv.
Note: On macOS the default camera source is `avfvideosrc` (AVFoundation). Linux defaults to `/dev/video0`.

## Quick start (docker)
Build/run with docker-compose from `nuvion_app/`:
```bash
cd nuvion_app
docker compose up --build
```

Optional build args (in `nuvion_app/inference/Dockerfile.inference`):
- `INSTALL_ZSAD_DEPS=true`
- `INSTALL_TRITON_DEPS=true`

## Setup UI (device)
If a display is available, run:
```bash
nuv-agent setup
```
This starts a local setup UI at `http://127.0.0.1:8088` (override with `--host/--port`).
The setup UI includes an **Auto Provision** section: login with an owner/admin account to create
device credentials automatically (your account credentials are not stored on the device).

For headless devices:
```bash
nuv-agent setup --qr
```
This prints a pairing URL/QR code. After approval in the web console, the device credentials
are saved to the config file.

Default config path:
- macOS (Homebrew): `/opt/homebrew/etc/nuv-agent/agent.env` (or `/usr/local/etc/nuv-agent/agent.env`)
- Linux: `/etc/nuv-agent/agent.env`

For dev, `.env` in the repo is used automatically.

## Service
- Linux: use `packaging/systemd/nuv-agent.service` and `systemctl enable --now nuv-agent`.
- macOS: use Homebrew service definition in `packaging/homebrew/nuv-agent.rb`.

## Device configuration
- `NUVION_VIDEO_SOURCE`: USB webcam path (e.g., `/dev/video0`) or `rpi` for Pi camera
- `NUVION_ANOMALY_LABELS`: comma-separated labels treated as anomalies
- `NUVION_PRODUCTION_LABELS`: comma-separated labels counted for production
- `NUVION_ZERO_SHOT_ENABLED`: enable optional zero-shot anomaly detection (requires model deps)
- `NUVION_ZSAD_BACKEND`: `siglip` 또는 `triton`
 - 기본 ZSAD 모델: `google/siglip2-base-patch16-224`

macOS note: use `NUVION_VIDEO_SOURCE=avf` (default camera) or `avf:<index>` to select a camera.

Optional deps:
- Zero-shot: `pip install -e .[zsad]`
- Triton: `pip install -e .[triton]`

## Macbook MPS demo (SigLIP2 ZSAD)
```bash
pip install -r nuvion_app/inference/requirements-zsad.txt
python -m nuvion_app.agent.zsad_siglip_demo --show
```

## Triton backend demo
```bash
# pip install -r nuvion_app/inference/requirements-triton.txt
NUVION_ZSAD_BACKEND=triton python -m nuvion_app.agent.zsad_siglip_demo
```

## Triton backend notes
- 기본은 **SigLIP2 base (google/siglip2-base-patch16-224)** 기준으로 맞춰져 있습니다.
- Triton 모델은 `siglip2-zsad`(기본값)으로 가정하며, 입력/출력 스펙은 `NUVION_TRITON_*`로 조정 가능합니다.

## Target platforms
- Jetson Nano / ARM 기반 장치 + Triton 서빙
- Apple Silicon Mac (MPS) 로컬 테스트

## Notes
- `nuvion_app/docker-compose.yml` is configured for Linux device runtime (USB camera).
