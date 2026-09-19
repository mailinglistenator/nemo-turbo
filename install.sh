#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "========================================"
echo "    Installing nemo-turbo (v1.1.0)"
echo "========================================"
echo ""

# 1. Dependency checks
if ! command -v python3 &>/dev/null; then
    echo "Error: python3 is required." >&2
    exit 1
fi

if ! command -v systemctl &>/dev/null; then
    echo "Error: systemd (systemctl) is required for user service." >&2
    exit 1
fi

if ! command -v wmctrl &>/dev/null; then
    echo "Notice: 'wmctrl' is not installed."
    echo "Full visible window paint benchmarks will be skipped unless installed via:"
    echo "  sudo apt install wmctrl"
    echo ""
fi

# 2. Install CLI & Systemd Service
echo "[1/2] Installing service and CLI..."
make install

# 3. Optional optimization
if [[ "$*" == *"--optimize"* ]]; then
    echo ""
    echo "[2/2] Applying safe Nemo engine optimizations..."
    "$HOME/.local/bin/nemo-turbo" optimize
else
    echo ""
    echo "[2/2] Note: Optional engine tweaks (disabling unused Samba probing) available via:"
    echo "  nemo-turbo optimize"
    echo "  (Reversible anytime via 'nemo-turbo restore')"
fi

echo ""
"$HOME/.local/bin/nemo-turbo" status

echo ""
echo "Installation complete! Test with:"
echo "  nemo-turbo bench"
