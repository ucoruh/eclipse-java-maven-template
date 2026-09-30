#!/bin/bash
# 4 - install / check every tool the numbered scripts use on Linux and WSL (WSL is Linux).
# Safe to re-run: every step checks first.
#   JDK 17 + Maven 3.8+ + .NET SDK   -> scripts/install-toolchain-linux.sh (per-user where apt is too old)
#   astyle, doxygen, graphviz, lcov (genhtml), zip, curl  -> apt-get
#   reportgenerator (dotnet tool)                          -> coverage / doc-coverage HTML, badges, history
#   Python packages from requirements.txt                  -> mkdocs-material, junit2html, coverxygen
#   gh (GitHub CLI)                                        -> 10-release
set -e
cd "$(dirname "$0")"

install_apt() {
    local pkg="$1" cmd="${2:-$1}"
    if command -v "$cmd" >/dev/null 2>&1; then echo "$cmd is already installed."
    else echo "Installing $pkg..."; sudo apt-get install -y "$pkg"; fi
}

command -v apt-get >/dev/null 2>&1 || { echo "[ERROR] apt-get not found. Install astyle, doxygen, graphviz, lcov, curl, zip, python3-pip with your package manager, then run the pip/dotnet steps of this script by hand." >&2; exit 1; }
sudo apt-get update
install_apt curl
install_apt zip
install_apt astyle
install_apt doxygen
install_apt graphviz dot
install_apt lcov genhtml
install_apt python3
install_apt python3-pip pip3

echo "== JDK 17 / Maven 3.8+ / .NET SDK 8+ =="
bash scripts/install-toolchain-linux.sh
. scripts/load-env-linux.sh   # picks the per-user Maven/.NET folders up for the rest of this run

echo "== ReportGenerator =="
dotnet tool update --global dotnet-reportgenerator-globaltool
command -v reportgenerator >/dev/null 2>&1 \
    || echo "NOTE: add to ~/.bashrc:  export PATH=\"\$PATH:\$HOME/.dotnet/tools\"  (scripts/load-env-linux.sh already does it for these scripts)"

echo "== Python packages (requirements.txt) =="
. scripts/detect-python-linux.sh
"$PY" -m pip install --user -r requirements.txt \
    || "$PY" -m pip install --user --break-system-packages -r requirements.txt

echo "== GitHub CLI =="
if ! command -v gh >/dev/null 2>&1; then
    echo "Installing GitHub CLI..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo apt-get update
    sudo apt-get install -y gh
else
    echo "GitHub CLI is already installed. Run 'gh auth login' once - see docs/guide/releases-en.md."
fi

echo "...................."
echo "All required tools checked/installed."
echo "...................."
