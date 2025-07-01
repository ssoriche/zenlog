#!/bin/bash

set -e

echo "🎨 Checking code formatting..."
echo

# Check Go code formatting with gofmt
echo "📝 Checking Go code formatting (gofmt)..."
unformatted=$(gofmt -s -l $(find . -type f -name '*.go') 2>/dev/null || true)
if [ -n "$unformatted" ]; then
  echo "❌ The following files are not properly formatted with gofmt:"
  echo "$unformatted"
  echo
  echo "💡 To fix: run 'gofmt -s -w .'"
  echo
  EXIT_CODE=1
else
  echo "✅ gofmt formatting is correct"
fi

# Check Go import formatting with goimports
echo
echo "📥 Checking Go import formatting (goimports)..."
if ! command -v goimports >/dev/null 2>&1; then
  echo "⚠️  goimports not found, installing..."
  go install golang.org/x/tools/cmd/goimports@latest
fi

unformatted=$(goimports -l $(find . -type f -name '*.go') 2>/dev/null || true)
if [ -n "$unformatted" ]; then
  echo "❌ The following files have incorrect import formatting:"
  echo "$unformatted"
  echo
  echo "💡 To fix: run 'goimports -w .'"
  echo
  EXIT_CODE=1
else
  echo "✅ goimports formatting is correct"
fi

# Check Go linting with golangci-lint (CI version)
echo
echo "🔍 Checking Go code quality (golangci-lint - CI version)..."
if bash "${0%/*}"/install-golangci-lint.sh; then
  GOLANGCI_LINT_BIN="$(go env GOPATH)/bin/golangci-lint"
  if "$GOLANGCI_LINT_BIN" run --timeout=5m >/dev/null 2>&1; then
    echo "✅ golangci-lint checks passed"
  else
    echo "❌ golangci-lint found issues:"
    "$GOLANGCI_LINT_BIN" run --timeout=5m --out-format=line-number
    echo
    echo "💡 This is the SAME version and config as CI! Fix these issues locally."
    echo "💡 To see detailed info: run '$GOLANGCI_LINT_BIN run'"
    EXIT_CODE=1
  fi
else
  echo "⚠️  Could not install golangci-lint, skipping linting checks"
fi

# Check shell script formatting if shellcheck is available
echo
echo "🐚 Checking shell script formatting..."
if command -v shellcheck >/dev/null 2>&1; then
  shell_issues=$(find . -name '*.sh' -type f -exec shellcheck {} \; 2>&1 || true)
  if [ -n "$shell_issues" ]; then
    echo "⚠️  Shellcheck found some issues:"
    echo "$shell_issues"
    echo
  else
    echo "✅ Shell scripts look good"
  fi
else
  echo "ℹ️  shellcheck not available, skipping shell script checks"
fi

echo
if [ "${EXIT_CODE:-0}" -eq 1 ]; then
  echo "❌ Some formatting issues found. Please fix them before committing."
  exit 1
else
  echo "🎉 All formatting checks passed!"
fi
