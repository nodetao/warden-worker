#!/usr/bin/env bash
set -euo pipefail

BW_WEB_VERSION="${BW_WEB_VERSION:-v2026.6.4}"
WORKER_BUILD_VERSION="${WORKER_BUILD_VERSION:-0.8.5}"
RUST_TOOLCHAIN="${RUST_TOOLCHAIN:-1.91.1}"
export CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
export RUSTUP_HOME="${RUSTUP_HOME:-$HOME/.rustup}"

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required to download the Rust toolchain and Web Vault frontend" >&2
  exit 1
fi

if ! command -v cargo >/dev/null 2>&1; then
  if ! command -v rustup >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
      | sh -s -- -y --profile minimal --default-toolchain "${RUST_TOOLCHAIN}"
  fi

  # shellcheck disable=SC1091
  . "${CARGO_HOME}/env"
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

rustup target add wasm32-unknown-unknown

worker-build --release --locked
