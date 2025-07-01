package util

import (
	"syscall"

	"github.com/omakoto/go-common/src/utils"
)

// StartEmergencyShell exec's /bin/sh.
func StartEmergencyShell() {
	Say("Starting emergency shell...")

	shell := "/bin/sh"
	err := syscall.Exec(shell, utils.StringSlice(shell), nil) // nolint:gosec // Intentional shell execution
	// syscall.Exec only returns if there's an error
	Fatalf("Failed to exec shell: %v", err)
}
