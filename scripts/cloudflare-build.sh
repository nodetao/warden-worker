#!/usr/bin/env bash
set -euo pipefail

BW_WEB_VERSION="${BW_WEB_VERSION:-v2026.6.4}"
WORKER_BUILD_VERSION="${WORKER_BUILD_VERSION:-0.8.5}"

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required to download the Web Vault frontend" >&2
  exit 1
fi

if [ ! -f "public/web-vault/index.html" ]; then
  archive="$(mktemp)"
  trap 'rm -f "${archive}"' EXIT
  curl -fsSL \
    "https://github.com/dani-garcia/bw_web_builds/releases/download/${BW_WEB_VERSION}/bw_web_${BW_WEB_VERSION}.tar.gz" \
    -o "${archive}"
  tar -xzf "${archive}" -C public
fi

find public/web-vault -type f -name '*.map' -delete
mkdir -p public/web-vault/css
cp public/css/vaultwarden.css public/web-vault/css/

if ! command -v worker-build >/dev/null 2>&1; then
  cargo install --locked -q worker-build --version "${WORKER_BUILD_VERSION}"
fi

if command -v rustup >/dev/null 2>&1; then
  rustup target add wasm32-unknown-unknown
fi

worker-build --release --locked
