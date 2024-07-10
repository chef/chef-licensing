package keyfetcher_test

import (
	"testing"

	keyfetcher "github.com/chef/chef-licensing/components/go/pkg/key_fetcher"
)

func TestFetchLicenseKeysBasedOnType(t *testing.T) {
	keyfetcher.SetFileHandler(keyfetcher.MockFileHandler{
		Content: []byte(TRIAL_ONLY_FILE),
		Error:   nil,
	})

	out := keyfetcher.FetchLicenseKeysBasedOnType(":trial")
	if len(out) == 0 {
		t.Log(out)
		t.Log(keyfetcher.GetFileHandler())
		t.Errorf("expected to return licenses, got %v", out)
		return
	}
	if out[0] != "tmns-123456" {
		t.Errorf("expected to return the %v, got %v", "tmns-123456", out)
	}
}

func TestFetchLicenseKeysBasedOnTypeInCaseOfNone(t *testing.T) {
	keyfetcher.SetFileHandler(keyfetcher.MockFileHandler{
		Content: []byte(""),
		Error:   nil,
	})
	out := keyfetcher.FetchLicenseKeysBasedOnType(":trial")
	if len(out) != 0 {
		t.Errorf("expected it to return empty list, got %v", out)
	}
}

func TestFetchLicenseTypeBasedOnKey(t *testing.T) {
	keyfetcher.SetFileHandler(keyfetcher.MockFileHandler{
		Content: []byte(TRIAL_ONLY_FILE),
		Error:   nil,
	})
	out := keyfetcher.FetchLicenseTypeBasedOnKey([]string{"tmns-123456"})
	if out != ":trial" {
		t.Errorf("expected it to return %v, got %v", ":trial", out)
	}
}
