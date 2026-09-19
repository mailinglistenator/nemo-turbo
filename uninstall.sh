#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Uninstalling nemo-turbo ==="
make uninstall

echo ""
echo "nemo-turbo has been completely removed."
echo "Stock Nemo launch behavior has been restored."
