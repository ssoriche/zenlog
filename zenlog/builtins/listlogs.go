package builtins

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/omakoto/zenlog/zenlog/config"
)

func listLogsCommand(args []string) {
	var top string
	if len(args) > 0 {
		top = args[0]
	} else {
		config := config.InitConfigForCommands()
		top = config.LogDir
	}

	err := filepath.Walk(top, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		rel, err := filepath.Rel(top, path)
		if err != nil {
			return err
		}

		if info.Mode().IsRegular() {
			fmt.Print("F ", rel, "\n")
			return nil
		}
		if (info.Mode() & os.ModeSymlink) != 0 {
			to, err := os.Readlink(path)
			if err != nil {
				return err
			}
			toRel, err := filepath.Rel(top, to)
			if err != nil {
				return err
			}

			fmt.Print("L ", rel, " -> ", toRel, "\n")
		}
		return nil
	})
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error walking directory: %v\n", err)
	}
}
