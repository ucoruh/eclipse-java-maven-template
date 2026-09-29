#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Checking for a supported Linux/WSL package manager..."
if command -v apt-get >/dev/null 2>&1; then
    echo "apt-get found (Debian/Ubuntu/WSL). Refreshing package lists..."
    sudo apt-get update
elif command -v dnf >/dev/null 2>&1; then
    echo "dnf found (Fedora)."
elif command -v pacman >/dev/null 2>&1; then
    echo "pacman found (Arch)."
else
    echo "[ERROR] No supported package manager (apt-get/dnf/pacman) found." >&2
    exit 1
fi

echo "Checking for a JDK 17+..."
if command -v java >/dev/null 2>&1 && java -version 2>&1 | grep -qE '"(1[7-9]|[2-9][0-9])'; then
    echo "JDK is already 17+: $(java -version 2>&1 | head -1)"
elif command -v apt-get >/dev/null 2>&1; then
    echo "Installing OpenJDK 17..."
    sudo apt-get install -y openjdk-17-jdk
else
    echo "[ERROR] No JDK 17+ found and no apt-get to install one." >&2
    exit 1
fi

echo "Checking for Maven 3.8+ (this project's pom.xml enforces 3.8+; Ubuntu's"
echo "apt package is often older, e.g. 3.6.3 on 20.04 - so this installs a"
echo "pinned current version per-user instead of relying on apt for Maven)..."
MVN_OK=0
if command -v mvn >/dev/null 2>&1; then
    MVN_VER="$(mvn -version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
    MVN_MAJOR="$(echo "$MVN_VER" | cut -d. -f1)"
    MVN_MINOR="$(echo "$MVN_VER" | cut -d. -f2)"
    if [ -n "$MVN_MAJOR" ] && { [ "$MVN_MAJOR" -gt 3 ] || { [ "$MVN_MAJOR" -eq 3 ] && [ "$MVN_MINOR" -ge 8 ]; }; }; then
        MVN_OK=1
        echo "Maven is already $MVN_VER (>= 3.8) - OK."
    else
        echo "Maven $MVN_VER found but it is older than 3.8."
    fi
fi
if [ "$MVN_OK" -eq 0 ]; then
    MVN_PIN="3.9.9"
    echo "Installing Maven $MVN_PIN into \$HOME/tools/apache-maven-$MVN_PIN (per-user, no sudo)..."
    mkdir -p "$HOME/tools"
    curl -sSL "https://archive.apache.org/dist/maven/maven-3/$MVN_PIN/binaries/apache-maven-$MVN_PIN-bin.tar.gz" \
        -o /tmp/apache-maven.tar.gz
    tar -xzf /tmp/apache-maven.tar.gz -C "$HOME/tools"
    rm -f /tmp/apache-maven.tar.gz
    echo "Add this to your ~/.bashrc: export PATH=\"\$HOME/tools/apache-maven-$MVN_PIN/bin:\$PATH\""
    export PATH="$HOME/tools/apache-maven-$MVN_PIN/bin:$PATH"
    mvn -version
fi

echo "Checking for a .NET SDK 8+ (ReportGenerator 5.5+ targets net8.0/9.0/10.0 -"
echo "an old SDK, e.g. the 3.1 that ships pre-installed on some images, can run"
echo "an already-installed ReportGenerator but cannot install/update one, since"
echo "it cannot restore a package that targets a newer framework than itself)..."
DOTNET_OK=0
if command -v dotnet >/dev/null 2>&1; then
    DOTNET_MAJOR="$(dotnet --version 2>/dev/null | cut -d. -f1)"
    if [ -n "$DOTNET_MAJOR" ] && [ "$DOTNET_MAJOR" -ge 8 ]; then
        DOTNET_OK=1
        echo ".NET SDK is already $(dotnet --version) (>= 8) - OK."
    else
        echo ".NET SDK $(dotnet --version) found but it is older than 8."
    fi
fi
if [ "$DOTNET_OK" -eq 0 ]; then
    echo "Installing the current LTS .NET SDK per-user via the official install"
    echo "script (no system-wide change, no sudo needed)..."
    curl -sSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh
    bash /tmp/dotnet-install.sh --channel LTS --install-dir "$HOME/.dotnet"
    echo "Add this to your ~/.bashrc (DOTNET_ROOT matters, not just PATH: without"
    echo "it, a dotnet tool's apphost can fail with \"You must install .NET to run"
    echo "this application\" / a missing-framework error even though the SDK is"
    echo "right there, because it resolves the runtime through DOTNET_ROOT first):"
    echo "  export DOTNET_ROOT=\"\$HOME/.dotnet\""
    echo "  export PATH=\"\$HOME/.dotnet:\$HOME/.dotnet/tools:\$PATH\""
    export DOTNET_ROOT="$HOME/.dotnet"
    export PATH="$HOME/.dotnet:$HOME/.dotnet/tools:$PATH"
    dotnet --version
fi

echo "Done. Run 4-install-required-apps.sh next."
