// Command go-template is the entrypoint for the CLI.
package main

import "github.com/justanotherspy/go-template/internal/cli"

// Build information. Populated at release time via -ldflags by GoReleaser
// (see .goreleaser.yaml) and by the Makefile `build` target.
var (
	version = "dev"
	commit  = "none"
	date    = "unknown"
)

func main() {
	cli.Execute(cli.BuildInfo{Version: version, Commit: commit, Date: date})
}
