# Changelog

All notable changes to this project will be documented in this file.

## 1.0.1

- Pin atuin to a GitHub release binary (arch-aware) instead of the mutable
  `setup.atuin.sh` installer, which broke the image build
- Add `# renovate:` hints to every pinned tool version and rewrite
  `renovate.json` so all dependencies are tracked
- Switch from opencode v1 to the v2 beta (`@opencode-ai/cli`, `opencode2`
  binary with `opencode` symlinked to it)
- Bump GitHub Actions to current majors
- Update `dotconfig` submodule to 212c73a

## 1.0.0

- Initial release
