.PHONY: help install-tools lint test e2e format check-format presubmit build clean

# Force bash shell for all commands (fish shell compatibility)
SHELL := /bin/bash

# Default target
help:
	@echo "📝 Zenlog Development Commands"
	@echo ""
	@echo "🔧 Setup:"
	@echo "  install-tools    Install all development tools (matches CI versions)"
	@echo ""
	@echo "🔍 Code Quality:"
	@echo "  lint            Run full linting (same as CI)"
	@echo "  format          Auto-fix code formatting"
	@echo "  check-format    Check formatting without fixing"
	@echo ""
	@echo "🧪 Testing:"
	@echo "  test            Run unit tests"
	@echo "  test-race       Run unit tests with race detection"
	@echo "  e2e             Run end-to-end tests"
	@echo ""
	@echo "🚀 Development:"
	@echo "  build           Build the zenlog binary"
	@echo "  presubmit       Run all checks before creating PR"
	@echo "  clean           Clean build artifacts"

# Install all development tools with versions matching CI
install-tools:
	@echo "🔧 Installing development tools (CI versions)..."
	@bash scripts/install-golangci-lint.sh
	@go install golang.org/x/tools/cmd/goimports@latest
	@go install honnef.co/go/tools/cmd/staticcheck@latest
	@go install golang.org/x/vuln/cmd/govulncheck@latest
	@echo "✅ All tools installed!"

# Run full linting (exactly like CI)
lint: install-tools
	@echo "🔍 Running full lint suite (same as CI)..."
	@gofmt -s -l $$(find . -type f -name '*.go') | \
	  if read -r line; then \
	    echo "❌ Unformatted Go files found:"; \
	    gofmt -s -l $$(find . -type f -name '*.go'); \
	    echo "💡 Run 'make format' to fix"; \
	    exit 1; \
	  fi
	@goimports -l $$(find . -type f -name '*.go') | \
	  if read -r line; then \
	    echo "❌ Import issues found:"; \
	    goimports -l $$(find . -type f -name '*.go'); \
	    echo "💡 Run 'make format' to fix"; \
	    exit 1; \
	  fi
	@echo "✅ Code formatting is correct"
	@go vet ./...
	@echo "✅ go vet passed"
	@staticcheck ./...
	@echo "✅ staticcheck passed"
	@$$(go env GOPATH)/bin/golangci-lint run --timeout=5m
	@echo "✅ golangci-lint passed"
	@govulncheck ./...
	@echo "✅ govulncheck passed"
	@echo "🎉 All linting checks passed!"

# Auto-fix code formatting
format: install-tools
	@echo "🎨 Auto-fixing code formatting..."
	@gofmt -s -w .
	@goimports -w .
	@echo "✅ Code formatting fixed!"

# Check formatting without fixing
check-format:
	@bash scripts/check-format.sh

# Run unit tests
test:
	@echo "🧪 Running unit tests..."
	@go test -v ./...

# Run unit tests with race detection
test-race:
	@echo "🧪 Running unit tests with race detection..."
	@go test -v -race ./...

# Run end-to-end tests
e2e: build
	@echo "🧪 Running end-to-end tests..."
	@for test in e2etests/test*.sh; do \
	  echo "Running $$test"; \
	  "$$test"; \
	done

# Build the zenlog binary
build:
	@echo "📦 Building zenlog..."
	@bash scripts/build.sh

# Run all presubmit checks
presubmit:
	@bash scripts/presubmit.sh

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf bin/
	@go clean -cache
	@echo "✅ Clean complete!"
