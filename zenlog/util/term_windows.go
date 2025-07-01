//go:build windows

package util

import (
	"fmt"
	"os"
)

func Ttyname(fd uintptr) string {
	// Windows doesn't have ttyname, return a generic name
	return "CON"
}

func Tty() string {
	// On Windows, always return CON (console)
	return "CON"
}

func PropagateTerminalSize(from, to *os.File) error {
	// Terminal size propagation is not supported on Windows
	// This is a no-op to maintain API compatibility
	return fmt.Errorf("PropagateTerminalSize not supported on Windows")
}
