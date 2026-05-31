# syntax=docker/dockerfile:1
#
# Multi-stage build producing a tiny, static, non-root image.
#
# The base images are Chainguard's (minimal, low/zero-CVE, continuously rebuilt).
# They are pinned by tag here and kept current by the `docker` Dependabot
# ecosystem (.github/dependabot.yml). For stronger supply-chain guarantees you
# can additionally pin by digest:
#
#   FROM cgr.dev/chainguard/go:latest@sha256:<digest> AS build
#
# Resolve the current digest with:
#
#   docker buildx imagetools inspect cgr.dev/chainguard/go:latest \
#     --format '{{.Manifest.Digest}}'

# ---- build stage ------------------------------------------------------------
# --platform=$BUILDPLATFORM keeps the toolchain native; we cross-compile to the
# requested TARGET* below, so no QEMU emulation is needed.
FROM --platform=$BUILDPLATFORM cgr.dev/chainguard/go:latest AS build

# Run the build as root so the module cache and output path are writable; this
# stage is discarded and never shipped.
USER root

# Build metadata, injected via --build-arg (mirrors the Makefile and GoReleaser).
ARG VERSION=dev
ARG COMMIT=none
ARG DATE=unknown

# Cross-compilation targets supplied by buildx for each requested platform.
ARG TARGETOS
ARG TARGETARCH

WORKDIR /src

# Download modules in their own layer so source-only changes don't re-fetch.
COPY go.mod go.sum ./
RUN go mod download

COPY . .

ENV CGO_ENABLED=0
RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -trimpath \
      -ldflags "-s -w -X main.version=${VERSION} -X main.commit=${COMMIT} -X main.date=${DATE}" \
      -o /go-template ./cmd/go-template

# ---- runtime stage ----------------------------------------------------------
FROM cgr.dev/chainguard/static:latest

# OCI metadata: lets GHCR, `docker scout`, etc. link the image to its source.
LABEL org.opencontainers.image.source="https://github.com/justanotherspy/go-template" \
      org.opencontainers.image.description="A batteries-included template for building Go command-line tools" \
      org.opencontainers.image.licenses="MIT"

COPY --from=build /go-template /usr/bin/go-template

# chainguard/static already defaults to the nonroot (65532) user.
ENTRYPOINT ["/usr/bin/go-template"]
