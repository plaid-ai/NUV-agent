# Packaging

This directory contains packaging templates for Homebrew and Debian/Ubuntu.

## Homebrew (tap)
1. Create a tap repo (e.g., `plaid-ai/NUV-agent-homebrew`).
2. Copy `packaging/homebrew/nuv-agent.rb` into `Formula/nuv-agent.rb`.
3. Replace `__URL__` and `__SHA256__` with the release tarball URL and SHA256.
4. Tag a release matching the formula version.

Recommended service env vars (already in the formula):
- `NUV_AGENT_CONFIG`
- `DYLD_LIBRARY_PATH`
- `GI_TYPELIB_PATH`
- `GST_PLUGIN_PATH`

## Debian/Ubuntu (.deb)
Build a package on the target architecture (e.g., Jetson ARM64):
```bash
cd NUV-agent/packaging/deb
./build-deb.sh
```

This script:
- Creates a venv under `/opt/nuv-agent/venv`.
- Installs the Python package.
- Installs the systemd unit.
- Creates `/etc/nuv-agent/agent.env` if missing.

Python requirement: 3.10+

Optional extras:
- Zero-shot: install `nuv-agent[zsad]`
- Triton: install `nuv-agent[triton]`

To include extras during package build:
```bash
EXTRAS=zsad ./build-deb.sh
```

## Release helpers
- `packaging/release/build-sdist.sh`: build source tarball and print SHA256.
- `packaging/release/update-homebrew-formula.sh`: inject URL/SHA/version into formula.
- `packaging/release/bootstrap-homebrew-tap.sh`: create and seed the tap repo.
- `packaging/apt/`: minimal `aptly` repo flow (GCS recommended).

## GitHub Actions release
Workflow: `.github/workflows/release.yml`

Required secrets:
- `HOMEBREW_TAP_TOKEN` (PAT with push access to `plaid-ai/NUV-agent-homebrew`)

To host an APT repo, use a tool like `aptly` or `reprepro`, then publish the generated `.deb`.
