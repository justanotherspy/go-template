# ==============================================================================
# go-template — developer Makefile
#
# Run `make help` to see all targets.
# Tool versions are pinned below and mirrored in the GitHub Actions workflows
# and .goreleaser.yaml. Bump them together.
# ==============================================================================

SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

# ---- Project ----------------------------------------------------------------
BINARY   := go-template
MAIN_PKG := ./cmd/$(BINARY)
BIN_DIR  := bin
DIST_DIR := dist
COVERAGE := coverage.out

# ---- Version / build metadata ----------------------------------------------
VERSION := $(shell cat VERSION 2>/dev/null || echo "0.0.0")
COMMIT  := $(shell git rev-parse --short HEAD 2>/dev/null || echo "none")
DATE    := $(shell date -u +%Y-%m-%dT%H:%M:%SZ)
LDFLAGS := -s -w -X main.version=$(VERSION) -X main.commit=$(COMMIT) -X main.date=$(DATE)

# ---- Pinned tool versions ---------------------------------------------------
GOLANGCI_LINT_VERSION := v2.12.2
GORELEASER_VERSION    := v2.16.0
GOTESTSUM_VERSION     := v1.13.0
GOVULNCHECK_VERSION   := latest
GOPLS_VERSION         := latest

GO    ?= go
GOBIN := $(shell $(GO) env GOPATH)/bin
export GOTOOLCHAIN ?= auto
export PATH := $(GOBIN):$(PATH)

# ==============================================================================
.PHONY: help
help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

# ---- Dependencies & tooling -------------------------------------------------
.PHONY: deps
deps: ## Download and verify Go module dependencies
	$(GO) mod download
	$(GO) mod verify

.PHONY: tidy
tidy: ## Tidy go.mod and go.sum
	$(GO) mod tidy

.PHONY: tools
tools: golangci-lint goreleaser gotestsum govulncheck lsp ## Install all pinned dev tools

.PHONY: check-tools
check-tools: ## Verify required tools are installed
	@missing=0; \
	for t in $(GO) git golangci-lint goreleaser govulncheck gopls; do \
		if command -v $$t >/dev/null 2>&1; then echo "  [ok] $$t"; \
		else echo "  [--] $$t  (run: make tools)"; missing=1; fi; \
	done; \
	exit $$missing

.PHONY: golangci-lint
golangci-lint: ## Install golangci-lint (v2) if missing
	@command -v golangci-lint >/dev/null 2>&1 || { \
		echo ">> installing golangci-lint $(GOLANGCI_LINT_VERSION)"; \
		$(GO) install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@$(GOLANGCI_LINT_VERSION); }

.PHONY: goreleaser
goreleaser: ## Install GoReleaser if missing
	@command -v goreleaser >/dev/null 2>&1 || { \
		echo ">> installing goreleaser $(GORELEASER_VERSION)"; \
		$(GO) install github.com/goreleaser/goreleaser/v2@$(GORELEASER_VERSION); }

.PHONY: gotestsum
gotestsum: ## Install gotestsum if missing
	@command -v gotestsum >/dev/null 2>&1 || { \
		echo ">> installing gotestsum $(GOTESTSUM_VERSION)"; \
		$(GO) install gotest.tools/gotestsum@$(GOTESTSUM_VERSION); }

.PHONY: govulncheck-install
govulncheck-install: ## (internal) install govulncheck if missing
	@command -v govulncheck >/dev/null 2>&1 || { \
		echo ">> installing govulncheck $(GOVULNCHECK_VERSION)"; \
		$(GO) install golang.org/x/vuln/cmd/govulncheck@$(GOVULNCHECK_VERSION); }

.PHONY: lsp
lsp: ## Install gopls (Go language server for editors & Claude Code)
	@command -v gopls >/dev/null 2>&1 || { \
		echo ">> installing gopls $(GOPLS_VERSION)"; \
		$(GO) install golang.org/x/tools/gopls@$(GOPLS_VERSION); }

# ---- Quality ----------------------------------------------------------------
.PHONY: fmt
fmt: golangci-lint ## Format code (gofmt + goimports via golangci-lint)
	golangci-lint fmt

.PHONY: vet
vet: ## Run go vet
	$(GO) vet ./...

.PHONY: lint
lint: golangci-lint ## Run golangci-lint
	golangci-lint run

.PHONY: lint-fix
lint-fix: golangci-lint ## Run golangci-lint with --fix
	golangci-lint run --fix

# ---- Tests ------------------------------------------------------------------
.PHONY: test
test: ## Run tests with the race detector and coverage
	$(GO) test -race -covermode=atomic -coverprofile=$(COVERAGE) ./...

.PHONY: test-pretty
test-pretty: gotestsum ## Run tests with pretty output (gotestsum)
	gotestsum -- -race -covermode=atomic -coverprofile=$(COVERAGE) ./...

.PHONY: cover
cover: test ## Print per-function coverage summary
	$(GO) tool cover -func=$(COVERAGE)

.PHONY: cover-html
cover-html: test ## Open the HTML coverage report
	$(GO) tool cover -html=$(COVERAGE)

# ---- Build / run ------------------------------------------------------------
.PHONY: build
build: ## Build the binary into ./bin
	@mkdir -p $(BIN_DIR)
	$(GO) build -trimpath -ldflags '$(LDFLAGS)' -o $(BIN_DIR)/$(BINARY) $(MAIN_PKG)

.PHONY: install
install: ## go install the binary
	$(GO) install -trimpath -ldflags '$(LDFLAGS)' $(MAIN_PKG)

.PHONY: run
run: ## Run the CLI (pass args via ARGS="...")
	$(GO) run $(MAIN_PKG) $(ARGS)

# ---- Security ---------------------------------------------------------------
.PHONY: vuln
vuln: govulncheck-install ## Scan dependencies for known vulnerabilities
	govulncheck ./...

.PHONY: security
security: vuln ## Run all local security checks
	@echo ">> security checks complete"

# ---- Release ----------------------------------------------------------------
.PHONY: release-check
release-check: goreleaser ## Validate the GoReleaser configuration
	goreleaser check

.PHONY: snapshot
snapshot: goreleaser ## Build a local snapshot release (no publish)
	goreleaser release --snapshot --clean

# ---- Aggregates -------------------------------------------------------------
.PHONY: ci
ci: deps lint test build ## Run the pipeline that CI runs

.PHONY: all
all: tidy fmt lint test build ## Tidy, format, lint, test, and build

.PHONY: clean
clean: ## Remove build artifacts
	rm -rf $(BIN_DIR) $(DIST_DIR) $(COVERAGE)
