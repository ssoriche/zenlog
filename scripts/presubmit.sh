#!/bin/bash

set -e

echo "🔧 Running presubmit checks..."
echo

# Build first to ensure everything compiles
echo "📦 Building..."
. "${0%/*}"/build.sh
echo "✅ Build successful"
echo

# Check Go code formatting with gofmt
echo "🎨 Checking Go code formatting (gofmt)..."
unformatted=$(gofmt -s -l $(find . -type f -name '*.go'))
if [ -n "$unformatted" ]; then
  echo "❌ The following files are not properly formatted:"
  echo "$unformatted"
  echo
  echo "💡 To fix: run 'gofmt -s -w .'"
  exit 1
fi
echo "✅ Go code formatting is correct"
echo

# Check Go import formatting with goimports
echo "📥 Checking Go import formatting (goimports)..."
if ! command -v goimports >/dev/null 2>&1; then
  echo "⚠️  goimports not found, installing..."
  go install golang.org/x/tools/cmd/goimports@latest
fi

unformatted=$(goimports -l $(find . -type f -name '*.go'))
if [ -n "$unformatted" ]; then
  echo "❌ The following files have incorrect import formatting:"
  echo "$unformatted"
  echo
  echo "💡 To fix: run 'goimports -w .'"
  exit 1
fi
echo "✅ Go import formatting is correct"
echo

# Run unit tests
echo "🧪 Running unit tests..."
go test -v -race ./...
echo "✅ Unit tests passed"
echo

# Static analysis
echo "🔍 Running static analysis..."

echo "  → go vet..."
go vet ./...
echo "  ✅ go vet passed"

echo "  → staticcheck..."
if ! command -v staticcheck >/dev/null 2>&1; then
  echo "⚠️  staticcheck not found, installing..."
  go install honnef.co/go/tools/cmd/staticcheck@latest
fi
staticcheck ./...
echo "  ✅ staticcheck passed"

echo "  → golangci-lint (CI version)..."
bash "${0%/*}"/install-golangci-lint.sh
"$(go env GOPATH)/bin/golangci-lint" run --timeout=5m
echo "  ✅ golangci-lint passed"

echo
echo "🎉 All presubmit checks passed! Ready to create PR."
