//go:build unix

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
	signal.Notify(sigch, syscall.SIGCHLD, syscall.SIGWINCH, syscall.SIGHUP, syscall.SIGUSR2)

	// Signal handler.
	go func() {
		for s := range sigch {
			switch s {
			case syscall.SIGWINCH:
				util.Debugf("Caught SIGWINCH")

				err := util.PropagateTerminalSize(os.Stdin, l.Master())
				if err != nil {
					util.Warn(err, "PropagateTerminalSize failed")
				}
				l.SendFlushRequest()

			case syscall.SIGHUP:
				util.Debugf("Caught SIGHUP")

				l.SendCloseRequest()

			case syscall.SIGCHLD:
				util.Debugf("Caught SIGCHLD")
				ps, err := l.Child().Process.Wait()
				if err != nil {
					util.Warn(err, "Wait failed")
					*childStatus = 255
				} else {
					*childStatus = ps.Sys().(syscall.WaitStatus).ExitStatus() // nolint:errcheck // ExitStatus() returns int, not error
				}
				l.OnChildDied()

			case syscall.SIGUSR2:
				util.Say("Caught SIGUSR2; dumping stacktraces.")
				dumpAllGoroutines()

			default:
				util.Say("Caught unexpected signal: %+v", s)
			}
		}
	}()
}
