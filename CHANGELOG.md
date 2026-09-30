# Changelog

All notable changes to this project will be documented in this file.

## 1.1.0

- Add headless Chrome for Testing as the browser prerequisite for
  browser-use's browser-harness CLI / MCP: arch-aware binary, runtime
  libraries, the `chrome-headless` launcher helper and `BU_CDP_URL`, with the
  Chrome version tracked by Renovate via a custom datasource
- Add pnpm (pinned, Renovate-tracked)
- Update base image to Ubuntu 26.04, Helm to 4.3.0 and Poetry to 2.5.1

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
