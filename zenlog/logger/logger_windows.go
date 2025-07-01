//go:build windows

package logger

import (
	"fmt"
	"os"

	"github.com/omakoto/zenlog/zenlog/config"
	"github.com/omakoto/zenlog/zenlog/util"
)

func mustMakeFifo(config *config.Config, suffix string) *os.File {
	// Windows doesn't support named pipes via Mkfifo syscall
	// For now, we'll create a regular temporary file as a fallback
	// This is not ideal but allows the build to succeed
	filename := fmt.Sprintf("%szenlog.%d%s.pipe", config.TempDir, config.ZenlogPid, suffix)
	os.Remove(filename)

	util.Debugf("Creating temp file '%s' (Windows fallback)...", filename)
	file, err := os.OpenFile(filename, os.O_CREATE|os.O_RDWR, 0o600)
	util.Check(err, "OpenFile failed for '%s'", filename)
	return file
}
