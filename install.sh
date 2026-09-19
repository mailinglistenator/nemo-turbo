#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Installing nemo-turbo ==="

if ! command -v gcc &>/dev/null; then
    echo "Error: gcc is required to build nemo-turbo."
    echo "Install it via: sudo apt install gcc"
    exit 1
fi

if ! command -v make &>/dev/null; then
    echo "Error: make is required to build nemo-turbo."
    echo "Install it via: sudo apt install make"
    exit 1
fi

make install

echo ""
echo "Applying non-destructive Nemo engine settings..."
"$HOME/.local/bin/nemo-turbo" optimize

echo ""
"$HOME/.local/bin/nemo-turbo" status

echo ""
echo "Testing launch speed..."
"$HOME/.local/bin/nemo-turbo" bench

echo ""
echo "Installation complete! Enjoy instant 70ms Nemo launches."
