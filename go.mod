module github.com/justanotherspy/go-template

go 1.25.0

// Build with a patched toolchain: the go 1.25.0 stdlib has known
// vulnerabilities (GO-2025-4007/4009/4010/4011, GO-2026-4601/4602) that are
// reachable from the CLI. go1.25.10 fixes them; the floor stays at 1.25.0.
toolchain go1.25.10

require (
	github.com/spf13/cobra v1.10.2
	github.com/spf13/viper v1.21.0
)

require (
	github.com/fsnotify/fsnotify v1.9.0 // indirect
	github.com/go-viper/mapstructure/v2 v2.4.0 // indirect
	github.com/inconshreveable/mousetrap v1.1.0 // indirect
	github.com/pelletier/go-toml/v2 v2.2.4 // indirect
	github.com/sagikazarmark/locafero v0.11.0 // indirect
	github.com/sourcegraph/conc v0.3.1-0.20240121214520-5f936abd7ae8 // indirect
	github.com/spf13/afero v1.15.0 // indirect
	github.com/spf13/cast v1.10.0 // indirect
	github.com/spf13/pflag v1.0.10 // indirect
	github.com/subosito/gotenv v1.6.0 // indirect
	go.yaml.in/yaml/v3 v3.0.4 // indirect
	golang.org/x/sys v0.29.0 // indirect
	golang.org/x/text v0.28.0 // indirect
)
