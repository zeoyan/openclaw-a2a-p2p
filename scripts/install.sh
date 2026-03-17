#!/usr/bin/env bash
set -euo pipefail

PLUGIN_DIR="${1:-$(cd "$(dirname "$0")/.." && pwd)}"

exec "$PLUGIN_DIR/scripts/install-and-init.sh" "$PLUGIN_DIR"
