# go-template

[![CI](https://github.com/justanotherspy/go-template/actions/workflows/ci.yml/badge.svg)](https://github.com/justanotherspy/go-template/actions/workflows/ci.yml)
[![CodeQL](https://github.com/justanotherspy/go-template/actions/workflows/codeql.yml/badge.svg)](https://github.com/justanotherspy/go-template/actions/workflows/codeql.yml)
[![Release](https://img.shields.io/github/v/release/justanotherspy/go-template?sort=semver)](https://github.com/justanotherspy/go-template/releases)
[![Go Reference](https://pkg.go.dev/badge/github.com/justanotherspy/go-template.svg)](https://pkg.go.dev/github.com/justanotherspy/go-template)

A batteries-included template for building Go command-line tools, with CI,
linting, security scanning, and automated releases wired up from day one.

<!-- TEMPLATE:START -->
## Using this template

1. Click **Use this template** → **Create a new repository**.
2. A one-shot GitHub Action (`template-cleanup.yml`) automatically rewrites the
   module path, command directory, binary name, and `CODEOWNERS` to match your
   new repository, then deletes itself.
3. Wait for the `Initialize from template` action to finish and pull the
   resulting commit.
4. Start building in `internal/cli/`.

> If you cloned this repo manually instead of using the template button, you can
> run the same substitutions yourself by replacing `justanotherspy/go-template`
> (module path) and `go-template` (binary / command directory) throughout.
<!-- TEMPLATE:END -->

## Features

- **CLI** built on Cobra + Viper (config file + env var support).
- **Makefile** covering deps, tools, lint, format, test, build, run, security,
  and release tasks. `make help` lists everything.
- **golangci-lint v2** with a curated linter + formatter set.
- **CI** (`ci.yml`): lint, test matrix (Go 1.25.x / 1.26.x), build, govulncheck,
  and a `go mod tidy` check.
- **Security**: CodeQL (Go), Semgrep CE uploading SARIF to code scanning, and
  govulncheck.
- **Releases**: release-drafter + GoReleaser, driven by a `VERSION` file.
- **Dependabot** for Go modules and GitHub Actions, with update groups.
- All GitHub Actions **pinned to commit SHAs**.
- `gopls` LSP + `CLAUDE.md` preconfigured for Claude Code.

## Requirements

- Go 1.25 or newer (`GOTOOLCHAIN=auto` will fetch the right toolchain).
- `make`.

## Quick start

```sh
make tools     # install dev tooling (golangci-lint, goreleaser, gopls, …)
make ci        # deps + lint + test + build
make run ARGS="version"
```

## Usage

```sh
go-template            # prints help
go-template version    # prints version / build info
go-template --help
```

Configuration is read (in order of precedence) from flags, environment
variables prefixed with `GO_TEMPLATE_`, and an optional config file
(`--config`, default `$HOME/.go-template.yaml`).

## Development

| Command         | Purpose                          |
| --------------- | -------------------------------- |
| `make lint`     | Run golangci-lint                |
| `make fmt`      | Format code                      |
| `make test`     | Run tests with race + coverage   |
| `make build`    | Build the binary into `./bin`    |
| `make vuln`     | Vulnerability scan (govulncheck) |
| `make snapshot` | Local GoReleaser snapshot build  |

See [`CLAUDE.md`](CLAUDE.md) for the full layout and conventions.

## Releasing

1. Bump [`VERSION`](VERSION) on `main`.
2. release-drafter maintains a draft release tagged `v<VERSION>`.
3. Publish the draft **as a pre-release** — this triggers tests, lint, and a
   GoReleaser build that attaches binaries, then auto-promotes the release to
   "latest".

## License

[MIT](LICENSE)
