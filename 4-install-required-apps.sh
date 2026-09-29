#!/bin/bash
set -e

cd "$(dirname "$0")"

# This installs exactly what this repo's own scripts use on Linux/WSL:
#   astyle, doxygen, graphviz (optional), lcov (genhtml), curl, zip (per-report
#   download bundles in target/site/downloads/, see 7-build-app.sh)
#   -> via apt-get, only if missing
#   reportgenerator (dotnet tool) -> 7-build-app.sh
#   coverxygen (python3 pip package) -> 7-build-app.sh
#   gh (GitHub CLI) -> 10-release.sh
# Re-running this script is safe: every step checks first.

install_apt() {
    local pkg="$1"
    local cmd="${2:-$1}"
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "$cmd is already installed."
    else
        echo "Installing $pkg..."
        sudo apt-get install -y "$pkg"
    fi
}

if command -v apt-get >/dev/null 2>&1; then
    install_apt astyle
    install_apt doxygen
    install_apt graphviz dot
    install_apt lcov genhtml
    install_apt curl
    install_apt zip
else
    echo "[ERROR] apt-get not found. Install astyle, doxygen, graphviz, lcov, curl and zip" >&2
    echo "        with your distribution's package manager." >&2
    exit 1
fi

echo "Checking for the .NET SDK..."
if ! command -v dotnet >/dev/null 2>&1; then
    echo "[ERROR] dotnet not found. Run 3-install-package-manager.sh first." >&2
    exit 1
fi

echo "Installing / updating the ReportGenerator global tool..."
dotnet tool update --global dotnet-reportgenerator-globaltool
if ! command -v reportgenerator >/dev/null 2>&1; then
    echo "NOTE: reportgenerator was installed into \$HOME/.dotnet/tools, which is"
    echo "      not on PATH yet. Add to ~/.bashrc:"
    echo "      export PATH=\"\$PATH:\$HOME/.dotnet/tools\""
fi

echo "Checking for python3/pip..."
if ! command -v python3 >/dev/null 2>&1; then
    echo "[ERROR] python3 not found. Install it: sudo apt-get install -y python3 python3-pip" >&2
    exit 1
fi

echo "Installing coverxygen for python3..."
python3 -m pip install --user coverxygen

echo "Checking for the GitHub CLI (needed by 10-release.sh)..."
if ! command -v gh >/dev/null 2>&1; then
    echo "Installing GitHub CLI..."
    if command -v apt-get >/dev/null 2>&1; then
        type -p curl >/dev/null || sudo apt-get install -y curl
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
        sudo apt-get update
        sudo apt-get install -y gh
    fi
else
    echo "GitHub CLI is already installed. Run 'gh auth login' once - see docs/guide/releases-en.md."
fi

echo "...................."
echo "All required tools checked/installed."
echo "...................."
