#!/usr/bin/env bash
set -euo pipefail

PLUGIN_DIR="${1:-$(cd "$(dirname "$0")/.." && pwd)}"

echo "Installing plugin from: $PLUGIN_DIR"
openclaw plugins install "$PLUGIN_DIR"
openclaw gateway restart
openclaw plugins list
