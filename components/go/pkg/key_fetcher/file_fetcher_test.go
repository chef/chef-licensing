package keyfetcher_test

import (
	"testing"

	keyfetcher "github.com/chef/chef-licensing/components/go/pkg/key_fetcher"
)

const trial_license = `
---
:licenses:
  - :license_key: tmns-123456
    :license_type: :trial
    :update_time: "2024-07-10T00:29:50+05:30"
:file_format_version: 4.0.0
:license_server_url: https://testing.license.chef.co/License
`

func TestFetchLicenseKeysBasedOnType(t *testing.T) {
	keyfetcher.SetFileHandler(keyfetcher.MockFileHandler{
		Content: []byte(trial_license),
		Error:   nil,
		Present: true,
	})

	out := keyfetcher.FetchLicenseKeysBasedOnType(":trial")
	if len(out) == 0 {
		t.Logf("the function output is: %s", out)
		t.Errorf("expected to return licenses: %v, got: %v", "tmns-123456", out)
		return
	}
	if out[0] != "tmns-123456" {
		t.Errorf("expected to return the %v, got %v", "tmns-123456", out[0])
	}
}

func TestFetchLicenseKeysBasedOnTypeInCaseOfNone(t *testing.T) {
	keyfetcher.SetFileHandler(keyfetcher.MockFileHandler{
		Content: []byte(""),
		Error:   nil,
		Present: false,
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
		Present: true,
	})
	out := keyfetcher.FetchLicenseTypeBasedOnKey([]string{"tmns-123456"})
	if out != ":trial" {
		t.Logf("out was: %s", out)
		t.Logf("handler is : %v, type is %T", *keyfetcher.GetFileHandler(), *keyfetcher.GetFileHandler())
		t.Errorf("expected it to return %v, got %v", ":trial", out)
	}
}

func TestFetchLicenseKeys(t *testing.T) {
	keyfetcher.SetFileHandler(keyfetcher.MockFileHandler{
		Content: []byte(TRIAL_ONLY_FILE),
		Error:   nil,
		Present: true,
	})

	out := keyfetcher.FetchLicenseKeys()
	if out[0] != "tmns-123456" {
		t.Errorf("expected it to return %v, got %v", []string{"tmns-123456"}, out)
	}
}
