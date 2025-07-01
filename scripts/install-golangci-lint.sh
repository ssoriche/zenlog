#!/bin/bash
set -euo pipefail

# Version must match the one used in .github/workflows/ci.yaml
GOLANGCI_LINT_VERSION="v1.64.8"

# Check if golangci-lint is installed and is the correct version
if command -v golangci-lint >/dev/null 2>&1; then
    CURRENT_VERSION=$(golangci-lint --version | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
    if [ "$CURRENT_VERSION" = "$GOLANGCI_LINT_VERSION" ]; then
        echo "✅ golangci-lint $GOLANGCI_LINT_VERSION is already installed"
        exit 0
    else
        echo "⚠️  golangci-lint $CURRENT_VERSION is installed, but CI uses $GOLANGCI_LINT_VERSION"
        echo "   Installing the correct version..."
    fi
else
    echo "📦 Installing golangci-lint $GOLANGCI_LINT_VERSION..."
fi

# Install golangci-lint with the exact version used in CI
if command -v go >/dev/null 2>&1; then
    echo "Installing via go install..."
    go install "github.com/golangci/golangci-lint/cmd/golangci-lint@$GOLANGCI_LINT_VERSION"
else
    echo "Go not found, installing via curl..."
    curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b "$(go env GOPATH)/bin" "$GOLANGCI_LINT_VERSION"
fi

# Verify installation
GOPATH_BIN="$(go env GOPATH)/bin/golangci-lint"
if [ -f "$GOPATH_BIN" ] && "$GOPATH_BIN" --version | grep -q "$GOLANGCI_LINT_VERSION"; then
    echo "✅ Successfully installed golangci-lint $GOLANGCI_LINT_VERSION"

    # Check if the correct version is in PATH
    if golangci-lint --version | grep -q "$GOLANGCI_LINT_VERSION"; then
        echo "✅ Correct version is in PATH"
    else
        echo "⚠️  Warning: A different version of golangci-lint is first in PATH:"
        echo "   $(which golangci-lint) ($(golangci-lint --version | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1))"
        echo "   But the correct version is available at: $GOPATH_BIN"
        echo ""
        echo "   To use the CI version, either:"
        echo "   1. Run: export PATH=\"$(go env GOPATH)/bin:\$PATH\""
        echo "   2. Or use: $GOPATH_BIN instead of golangci-lint"
        echo ""
        echo "   The Makefile and scripts will automatically use the correct version."
    fi
else
    echo "❌ Failed to install golangci-lint $GOLANGCI_LINT_VERSION"
    exit 1
fi
