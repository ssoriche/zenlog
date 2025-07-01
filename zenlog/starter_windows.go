//go:build windows

package zenlog

import (
	"os"
	"os/signal"
	"syscall"

	"github.com/omakoto/zenlog/zenlog/logger"
	"github.com/omakoto/zenlog/zenlog/util"
)

func setupSignalHandler(l *logger.Logger, childStatus *int) {
	sigch := make(chan os.Signal, 1)
	// Only use signals available on Windows
	signal.Notify(sigch, os.Interrupt, syscall.SIGTERM)

	// Signal handler.
	go func() {
		for s := range sigch {
			switch s {
			case os.Interrupt:
				util.Debugf("Caught Ctrl+C")
				l.SendCloseRequest()

			case syscall.SIGTERM:
				util.Debugf("Caught SIGTERM")
				l.SendCloseRequest()

			default:
				util.Say("Caught unexpected signal: %+v", s)
			}
		}
	}()

	// On Windows, we need to handle child process completion differently
	// since SIGCHLD doesn't exist. We'll need to poll or use a different mechanism.
	go func() {
		if l.Child() != nil && l.Child().Process != nil {
			ps, err := l.Child().Process.Wait()
			if err != nil {
				util.Warn(err, "Wait failed")
				*childStatus = 255
			} else {
				// On Windows, use the exit code directly
				*childStatus = ps.ExitCode()
			}
			l.OnChildDied()
		}
	}()
}
