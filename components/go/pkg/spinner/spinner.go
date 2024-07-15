package spinner

import (
	"time"

	"github.com/theckman/yacspin"
)

func GetSpinner(suffix string) (*yacspin.Spinner, error) {
	SpinnerConfig := yacspin.Config{
		Frequency:       100 * time.Millisecond,
		CharSet:         yacspin.CharSets[59],
		Suffix:          suffix,
		SuffixAutoColon: true,
	}

	return yacspin.New(SpinnerConfig)
}
