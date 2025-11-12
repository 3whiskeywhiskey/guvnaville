#!/bin/bash
# Session start hook for Ashes to Empire
# Installs Godot 4.2.2 for testing

set -e

GODOT_VERSION="4.2.2"
GODOT_BUILD="stable"
GODOT_DIR="$HOME/.local/bin"
GODOT_BINARY="$GODOT_DIR/godot"

# Check if Godot is already installed
if command -v godot &> /dev/null; then
    CURRENT_VERSION=$(godot --version 2>&1 | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
    if [[ "$CURRENT_VERSION" == "$GODOT_VERSION"* ]]; then
        echo "✅ Godot $GODOT_VERSION already installed"
        exit 0
    fi
fi

echo "📦 Installing Godot $GODOT_VERSION..."

# Create directory
mkdir -p "$GODOT_DIR"

# Download Godot headless (for CI/CD and testing)
GODOT_URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-${GODOT_BUILD}/Godot_v${GODOT_VERSION}-${GODOT_BUILD}_linux.x86_64.zip"

echo "Downloading from: $GODOT_URL"
wget -q -O /tmp/godot.zip "$GODOT_URL"

# Extract
unzip -q /tmp/godot.zip -d /tmp/
mv /tmp/Godot_v${GODOT_VERSION}-${GODOT_BUILD}_linux.x86_64 "$GODOT_BINARY"
chmod +x "$GODOT_BINARY"

# Clean up
rm /tmp/godot.zip

# Add to PATH if not already there
if [[ ":$PATH:" != *":$GODOT_DIR:"* ]]; then
    export PATH="$GODOT_DIR:$PATH"
    echo "export PATH=\"$GODOT_DIR:\$PATH\"" >> ~/.bashrc
fi

echo "✅ Godot $GODOT_VERSION installed successfully"
godot --version
