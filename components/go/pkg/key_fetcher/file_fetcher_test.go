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
	})

	out := keyfetcher.FetchLicenseKeysBasedOnType(":trial")
	new := keyfetcher.FetchLicenseKeys()
	if len(out) == 0 {
		handler := *keyfetcher.GetFileHandler()
		data, _ := handler.ReadFile("test")
		t.Logf("out was: %s", out)
		t.Logf("handler is : %v, type is %T", handler, handler)
		t.Logf("handler data is: %v", string(data))
		t.Logf("the keys are: %v", new)
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
