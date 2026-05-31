# CLAUDE.md

Guidance for Claude Code (and humans) working in this repository.

## What this is

A template for a Go command-line application built with
[Cobra](https://github.com/spf13/cobra) and
[Viper](https://github.com/spf13/viper). It ships with CI, linting, security
scanning, and an automated release pipeline. New repositories created from the
template are auto-initialized by `.github/workflows/template-cleanup.yml`, which
rewrites the module path, command directory, and binary name to match the new
repo.

## Layout

```
cmd/go-template/      main package; injects build info and calls internal/cli
internal/cli/         command tree (root + subcommands), config loading
.github/workflows/    CI, CodeQL, Semgrep, secret-scan, zizmor, labeler,
                      release-drafter, release, cleanup
.github/ISSUE_TEMPLATE/  bug-report + feature-request issue forms
.github/labels.yml    canonical repo labels (synced by the labeler workflow)
.golangci.yml         golangci-lint v2 config (linters + formatters)
.goreleaser.yaml      GoReleaser v2 build/release config
install.sh            checksum-verified prebuilt-binary installer (curl | bash)
SECURITY.md           security policy / private vulnerability reporting
CONTRIBUTING.md       contributor guide
VERSION               single source of truth for the next release version
Makefile              all developer + CI tasks
```

## Common commands

Run `make help` for the full list. The essentials:

| Command              | Purpose                                            |
| -------------------- | -------------------------------------------------- |
| `make deps`          | Download and verify modules                        |
| `make tools`         | Install pinned dev tools (lint, releaser, gopls…)  |
| `make check-tools`   | Verify required tools are installed                |
| `make lint`          | Run golangci-lint v2                               |
| `make fmt`           | Format (gofmt + goimports via golangci-lint)       |
| `make modernize`     | Apply go1.26 modernizers in place (`go fix`)       |
| `make modernize-check` | Report (don't apply) code `go fix` would modernize |
| `make test`          | Tests with race detector + coverage                |
| `make build`         | Build to `./bin`                                   |
| `make run ARGS=...`  | Run the CLI                                        |
| `make vuln`          | govulncheck vulnerability scan                     |
| `make secrets`       | TruffleHog secret scan of the working tree         |
| `make zizmor`        | Audit GitHub Actions workflows (zizmor)            |
| `make actionlint`    | Lint workflows (+ shellcheck on run: blocks)       |
| `make release-check` | Validate `.goreleaser.yaml`                        |
| `make snapshot`      | Local snapshot build (no publish)                  |
| `make ci`            | What CI runs: deps + lint + modernize + test + build |

## Conventions

- Go **1.26+** (module floor is `go 1.26.0`; CI tests 1.26.x).
- `GOTOOLCHAIN=auto` — the correct Go toolchain is fetched on demand. The
  `toolchain` directive in `go.mod` pins a patched build toolchain (a bare
  `go 1.26.0` stdlib can carry vulnerabilities flagged by govulncheck); bump it
  when a newer patch fixes a reported issue.
- Lint must pass: `make lint`. Format with `make fmt` before committing.
- Code is kept modern with `go fix`: Go 1.26 rewrote `go fix` to run the
  [`modernize`](https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/modernize)
  analyzer suite (e.g. `any`, `minmax`, `rangeint`, `slicescontains`,
  `stringscut`, `newexpr`). `make modernize` applies the fixes; CI runs
  `make modernize-check` (`go fix -diff`, which exits non-zero on any diff), so
  the tree must stay modernized. Run `go tool fix help` to list the fixers.
- All GitHub Actions are pinned to commit SHAs; Dependabot keeps them current.
- Add new subcommands under `internal/cli/` and register them in `root.go`.
- Build metadata (`version`, `commit`, `date`) lives in `package main` and is
  injected via `-ldflags`. Update the user-facing version in the `VERSION` file.

## Tooling / LSP

`gopls` is the Go language server. `make lsp` installs it, and a `SessionStart`
hook in `.claude/settings.json` installs it automatically for web sessions.

## Release process

1. Merge PRs into `main`. release-drafter keeps a **draft** release updated; its
   version/tag come from the `VERSION` file (`v<VERSION>`).
2. To cut a release, edit the draft and publish it **as a pre-release**.
3. Publishing as pre-release triggers `release.yml`: it runs lint + tests, then
   GoReleaser builds binaries and appends them to the release. It also:
   - signs `checksums.txt` with **cosign** (keyless OIDC — the job has
     `id-token: write`); verify with the published `checksums.txt.sigstore.json`,
   - generates an **SPDX SBOM** per archive (via `syft`, installed in the job),
   - pushes a **Homebrew cask** to `justanotherspy/homebrew-tap` when the
     `HOMEBREW_TAP_GITHUB_TOKEN` secret is set (skipped otherwise, so a missing
     token never fails a release).
4. On success the release is automatically promoted (pre-release flag cleared,
   marked "latest").

To release a new version, bump `VERSION` on `main` first so the draft picks up
the new number.

### Distribution / cask

- `homebrew_casks` in `.goreleaser.yaml` generates the cask; the tap owner is
  `justanotherspy` (change it to publish to a different tap). The cask name,
  binary, homepage, and url track the repo name, so repos generated from the
  template publish their own cask automatically.
- `install.sh` is a standalone `curl | bash` installer that downloads the
  matching release archive, verifies it against `checksums.txt`, and installs
  the binary. Its override env vars (`<BINARY>_VERSION` / `<BINARY>_INSTALL_DIR`)
  track the binary name, matching the `viper` env prefix.
- `make snapshot` builds locally with `--skip=sign,sbom`, so cosign and syft are
  only needed in CI.
