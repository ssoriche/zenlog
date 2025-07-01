package util

import (
	"os"
	"syscall"

	"github.com/omakoto/go-common/src/common"
)

// MustExec is a must-version of syscall.Exec.
func MustExec(args []string) {
	common.Debugf("Executing: %v", args)

	err := syscall.Exec(args[0], args, os.Environ()) // nolint:gosec // Intentional command execution
	common.Checkf(err, "Exec failed args=%v", args)
}
