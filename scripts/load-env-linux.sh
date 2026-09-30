#!/bin/bash
# Helper (not a numbered script). Source it from the repo root:
#     . scripts/load-env-linux.sh
# Sets PROJECT_NAME, VERSION, GITHUB_REPO (from project.env), PLATFORM=linux (native Linux AND WSL),
# ARCH=x64|arm64. Never exits the caller's shell; returns non-zero on error.
if [ ! -f project.env ]; then
    echo "[ERROR] project.env not found in $(pwd) - run the scripts from the repository root." >&2
    return 1 2>/dev/null || exit 1
fi
while IFS='=' read -r _k _v; do
    _k="${_k//$'\r'/}"; _v="${_v//$'\r'/}"
    case "$_k" in ''|'#'*) continue ;; esac
    export "$_k=$_v"
done < project.env
unset _k _v
export PLATFORM=linux
case "$(uname -m)" in
    aarch64|arm64) export ARCH=arm64 ;;
    *) export ARCH=x64 ;;
esac
[ -n "$PROJECT_NAME" ] && [ -n "$VERSION" ] || { echo "[ERROR] PROJECT_NAME/VERSION missing in project.env." >&2; return 1 2>/dev/null || exit 1; }
# a per-user toolchain installed by 4-install-tools-linux.sh (no sudo) is picked up automatically
for d in "$HOME"/tools/apache-maven-*/bin "$HOME/.dotnet" "$HOME/.dotnet/tools" "$HOME/.local/bin"; do
    [ -d "$d" ] && case ":$PATH:" in *":$d:"*) ;; *) PATH="$d:$PATH" ;; esac
done
[ -d "$HOME/.dotnet" ] && export DOTNET_ROOT="$HOME/.dotnet"
export PATH
