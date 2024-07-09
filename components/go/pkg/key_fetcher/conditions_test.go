package keyfetcher_test

import (
	"fmt"
	"net/http"
	"testing"
	"time"

	keyfetcher "github.com/chef/chef-licensing/components/go/pkg/key_fetcher"
)

const TRIAL_ONLY_FILE = `
:licenses:
- :license_key: tmns-123456
  :license_type: :trial
  :update_time: "2024-07-10T00:29:50+05:30"
:file_format_version: 4.0.0
:license_server_url: https://testing.license.chef.co/License
`

func TestIsLienseRestricted(t *testing.T) {
	output := keyfetcher.IsLicenseRestricted("free")

	if output {
		t.Errorf("expected to have no restriction, got %v", output)
	}
}

// func TestDoesUserHasActiveTrialLicenseSuccess(t *testing.T) {
// 	valid_response := fmt.Sprintf(VALID_CLIENT_RESPONSE, time.Now().Add(time.Hour*60).Format("2006-01-02T15:04:05-07:00"))
// 	mockServer := mockAPIResponse(valid_response, http.StatusOK)
// 	defer mockServer.Close()
// 	// Give some time to the mock server to start
// 	time.Sleep(100 * time.Millisecond)

// 	keyfetcher.SetFileHandler(keyfetcher.MockFileHandler{
// 		Content: []byte(TRIAL_ONLY_FILE),
// 		Error:   nil,
// 	})

// 	out := keyfetcher.DoesUserHasActiveTrialLicense()
// 	if !out {
// 		t.Errorf("expected to return true, got %v", out)
// 	}
// }

func TestDoesUserHasActiveTrialFailure(t *testing.T) {
	valid_response := fmt.Sprintf(VALID_CLIENT_RESPONSE, time.Now().Add(time.Hour*60).Format("2006-01-02T15:04:05-07:00"))
	mockServer := mockAPIResponse(valid_response, http.StatusOK)
	defer mockServer.Close()
	keyfetcher.SetFileHandler(keyfetcher.MockFileHandler{
		Content: []byte(""),
	})

	out := keyfetcher.DoesUserHasActiveTrialLicense()
	if out {
		t.Errorf("expected to return false, got %v", out)
	}
}

func TestHasUnrestrictedLienseAdded(t *testing.T) {
	setConfig("http://testing.chef.io")
	keyfetcher.SetFileHandler(keyfetcher.MockFileHandler{
		Content: []byte(""),
	})

	out := keyfetcher.HasUnrestrictedLicenseAdded([]string{"key-123"}, "trial")
	if !out {
		t.Errorf("expected it to be %v, got %v", true, out)
	}
}

// func TestHasUnrestrictedLienseAddedFailure(t *testing.T) {
// 	setConfig("http://testing.chef.io")
// 	keyfetcher.SetFileHandler(keyfetcher.MockFileHandler{
// 		Content: []byte(TRIAL_ONLY_FILE),
// 	})

// 	out := keyfetcher.HasUnrestrictedLicenseAdded([]string{"key-123"}, "free")
// 	if out {
// 		t.Errorf("expected it to be %v, got %v", false, out)
// 	}
// }
