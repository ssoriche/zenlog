//go:build unix

package logger

import (
	"fmt"
	"os"
	"syscall"

	"github.com/omakoto/zenlog/zenlog/config"
	"github.com/omakoto/zenlog/zenlog/util"
)

func mustMakeFifo(config *config.Config, suffix string) *os.File {
	filename := fmt.Sprintf("%szenlog.%d%s.pipe", config.TempDir, config.ZenlogPid, suffix)
	os.Remove(filename)

	util.Debugf("Making fifo '%s'...", filename)
	err := syscall.Mkfifo(filename, 0o600)
	util.Check(err, "Makefifo failed for '%s'", filename)

	file, err := os.OpenFile(filename, os.O_RDWR, 0o600)
	util.Check(err, "OpenFile failed for '%s'", filename)
	return file
}
