package logfiles

import (
	"fmt"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/omakoto/go-common/src/utils"
	"github.com/omakoto/zenlog/zenlog/config"
	"github.com/omakoto/zenlog/zenlog/util"
)

func TestCreateLogFiles(t *testing.T) {
	config := config.Config{}

	config.LogDir = "/tmp/zenlog-test/log/"
	config.ZenlogPid = 111
	config.PrefixCommands = "(?:time|sudo|[a-zA-Z0-9_]+=.*)"

	os.RemoveAll(config.LogDir)

	// Use system local time to make test portable across different timezones
	baseTime := time.Unix(1319202062, 123*1000*1000).Local()

	// Generate expected log paths for each test case
	tests := []struct {
		commandLine string
		timeOffset  time.Duration
		logSuffix   string
	}{
		{"/bin/echo ok", 0, "_+echo_ok.log"},
		{"/bin/echo ok # comment tag ", time.Minute, "_+comment_tag_+echo_ok_comment_tag.log"},
		{"echo ok", 2 * time.Minute, "_+echo_ok.log"},
		{"./echo ok", 3 * time.Minute, "_+echo_ok.log"},
		{"time echo ok", 4 * time.Minute, "_+time_echo_ok.log"},
	}

	clock := utils.NewInjectedClock(baseTime)
	for _, v := range tests {
		testTime := baseTime.Add(v.timeOffset)
		expectedPath := fmt.Sprintf("/tmp/zenlog-test/log/SAN/%04d/%02d/%02d/%02d-%02d-%02d.%03d-%05d%s",
			testTime.Year(), testTime.Month(), testTime.Day(),
			testTime.Hour(), testTime.Minute(), testTime.Second(),
			testTime.Nanosecond()/1000000, config.ZenlogPid, v.logSuffix)

		actual := CreateAndOpenLogFiles(&config, clock.Now(), ParseCommandLine(&config, v.commandLine))
		defer actual.Close()
		util.AssertStringsEqual(t, v.commandLine, expectedPath, actual.SanFile)
		util.AssertStringsEqual(t, v.commandLine, strings.Replace(expectedPath, "SAN", "RAW", 1), actual.RawFile)
		util.AssertStringsEqual(t, v.commandLine, strings.Replace(expectedPath, "SAN", "ENV", 1), actual.EnvFile)
		util.AssertFileExist(t, actual.SanFile)
		util.AssertFileExist(t, actual.RawFile)
		util.AssertFileExist(t, actual.EnvFile)

		clock = utils.NewInjectedClock(clock.Now().Add(time.Minute))
	}
}
