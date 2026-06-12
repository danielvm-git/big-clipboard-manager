#!/usr/bin/env bash
# setup.sh — Idempotent environment setup and project generation.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "Checking environment dependencies..."

# Check if xcodegen is installed, if not try to install it
if ! command -v xcodegen &> /dev/null; then
    echo "xcodegen not found. Attempting to install via Homebrew..."
    if command -v brew &> /dev/null; then
        brew install xcodegen
    else
        echo "Error: Homebrew is not installed. Please install xcodegen manually."
        exit 1
    fi
else
    echo "xcodegen is already installed."
fi

echo "Regenerating Xcode project..."
xcodegen --spec project.yml

echo "Running unit tests to verify development environment..."
xcodebuild test -project BigClipboard.xcodeproj -scheme BigClipboard -only-testing BigClipboardTests

echo "Setup completed successfully."
