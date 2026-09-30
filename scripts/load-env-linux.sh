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
# A per-user toolchain installed by 4-install-tools-linux.sh (no sudo) is picked up automatically.
# DOTNET_ROOT is only set when a real .NET install lives in ~/.dotnet: "dotnet tool install --global"
# also creates ~/.dotnet/tools, and pointing DOTNET_ROOT at a folder without the runtime would break
# ReportGenerator ("You must install .NET to run this application").
for d in "$HOME"/tools/apache-maven-*/bin "$HOME/.dotnet/tools" "$HOME/.local/bin"; do
    if [ -d "$d" ]; then case ":$PATH:" in *":$d:"*) ;; *) PATH="$d:$PATH" ;; esac; fi
done
if [ -x "$HOME/.dotnet/dotnet" ]; then
    export DOTNET_ROOT="$HOME/.dotnet"
    case ":$PATH:" in *":$HOME/.dotnet:"*) ;; *) PATH="$HOME/.dotnet:$PATH" ;; esac
fi
export PATH
return 0 2>/dev/null || true
