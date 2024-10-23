package keyfetcher_test

import (
	"bytes"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
	"time"

	"github.com/chef/chef-licensing/components/go/pkg/config"
	keyfetcher "github.com/chef/chef-licensing/components/go/pkg/key_fetcher"
	"gopkg.in/yaml.v2"
)

type actionFunction func() string

const YAML_DATA = `
interactions:
  test_say:
    messages: ["First Message"]
    prompt_type: "Say"
    paths: [next_path_after_say]

  ask_for_license_timeout:
    messages: ["Please choose one of the options below"]
    options: ["Option A", "Option B"]
    prompt_type: "TimeoutSelect"
    prompt_attributes:
      timeout_continue: true
      timeout_duration: 1
      timeout_message: "Prompt timed out. Use non-interactive flags or enter an answer within 60 seconds."
    paths: [next_path_after_timeout]
  warn:
    messages: ["This is a warn"]
    paths: [path_after_warn]
  error:
    messages: ["This is a error"]
    paths: [path_after_error]
  ok:
    messages: ["This is a ok"]
    paths: [path_after_ok]
`
const VALID_CLIENT_RESPONSE = `
{
	"data": {
		"client": {
			"license": "trial",
			"status": "Active",
			"changesTo": "Expired",
			"changesOn": "%s",
			"changesIn": 5,
			"usage": "Active",
			"used": 0,
			"limit": 1,
			"measure": "node"
		}
	},
	"message": "",
	"status_code": 200
}
`

func TestSayAction(t *testing.T) {
	actions := loadInteractions()

	detail := actions["test_say"]

	stdOut, funcOut := readFromSTDOUT(detail.Say)
	if stdOut != "\nFirst Message" {
		t.Errorf("expected %q but got %q", "First Message", stdOut)
	}
	if funcOut != "next_path_after_say" {
		t.Errorf("expected %q but got %q", "next_path_after_say", funcOut)
	}
}

func TestTimeoutSelect(t *testing.T) {
	actions := loadInteractions()

	detail := actions["ask_for_license_timeout"]
	_, funcOut := readFromSTDOUT(detail.TimeoutSelect)

	if funcOut != "" {
		t.Errorf("expected %q but got %q", "", funcOut)
	}
}

func TestWarnAction(t *testing.T) {
	actions := loadInteractions()
	detail := actions["warn"]

	stdOut, funcOut := readFromSTDOUT(detail.Warn)
	if stdOut != "\nThis is a warn" {
		t.Errorf("expected %q but got %q", "This is a warn", stdOut)
	}
	if funcOut != "path_after_warn" {
		t.Errorf("expected %q but got %q", "path_after_warn", funcOut)
	}
}

func TestErrorAction(t *testing.T) {
	actions := loadInteractions()
	detail := actions["error"]

	stdOut, funcOut := readFromSTDOUT(detail.Error)
	if stdOut != "\nThis is a error" {
		t.Errorf("expected %q but got %q", "This is a error", stdOut)
	}
	if funcOut != "path_after_error" {
		t.Errorf("expected %q but got %q", "path_after_error", funcOut)
	}
}

func TestOkAction(t *testing.T) {
	actions := loadInteractions()
	detail := actions["ok"]

	stdOut, funcOut := readFromSTDOUT(detail.Ok)
	if stdOut != "\nThis is a ok" {
		t.Errorf("expected %q but got %q", "This is a ok", stdOut)
	}
	if funcOut != "path_after_ok" {
		t.Errorf("expected %q but got %q", "path_after_ok", funcOut)
	}
}

func TestDoesLicenseHaveValidPattern(t *testing.T) {
	ad := keyfetcher.ActionDetail{
		Action: "DoesLicenseHaveValidPattern",
		ResponsePathMap: map[string]string{
			"true":  "valid_pattern",
			"false": "invalid_pattern",
		},
	}
	// Set the license to an invalid pattern and test the scenario
	keyfetcher.SetLastUserInput("test-1234")
	out := ad.PerformInteraction()
	if out != "invalid_pattern" {
		t.Errorf("expected the pattern to be %v, got %v", "invalid_pattern", out)
	}

	// Set the license to a valid pattern and test the success scenario
	keyfetcher.SetLastUserInput("3ff52c37-e41f-4f6c-ad4d-365192205968")
	out = ad.PerformInteraction()
	if out != "valid_pattern" {
		t.Errorf("expected the pattern to be %v, got %v", "valid_pattern", out)
	}
}

func TestIsLicenseAllowed(t *testing.T) {
	keyfetcher.SetFileHandler(keyfetcher.MockFileHandler{
		Content: []byte(""),
		Error:   nil,
	})

	valid_response := fmt.Sprintf(VALID_CLIENT_RESPONSE, time.Now().Add(time.Hour*60).Format("2006-01-02T15:04:05-07:00"))

	mockServer := mockAPIResponse(valid_response, http.StatusOK)
	defer mockServer.Close()

	ad := keyfetcher.ActionDetail{
		Action: "IsLicenseAllowed",
		ResponsePathMap: map[string]string{
			"true":  "license_allowed",
			"false": "license_not_allowed",
		},
	}

	// Set the license to an invalid pattern and test the scenario
	keyfetcher.SetLastUserInput("3ff52c37-e41f-4f6c-ad4d-365192205968")
	out := ad.PerformInteraction()

	if out != "license_allowed" {
		t.Errorf("expected the function to return %v, got %v", "license_allowed", out)
	}
}

func TestDeterminteRestrictionType(t *testing.T) {
	keyfetcher.UpdatePromptInputs(map[string]string{
		"LicenseType": "trial",
	})

	ad := keyfetcher.ActionDetail{
		Action: "DetermineRestrictionType",
		ResponsePathMap: map[string]string{
			"trial_restriction":        "trial_already_exist_message",
			"free_restriction":         "free_license_already_exist_message",
			"active_trial_restriction": "active_trial_exist_message",
		},
	}
	out := ad.PerformInteraction()
	if out != "trial_already_exist_message" {
		t.Errorf("expected the restriction to be %s, got %s", "trial_already_exist_message", out)
	}
}

func TestFetchLicenseTypeRestricted(t *testing.T) {
	keyfetcher.SetFileHandler(keyfetcher.MockFileHandler{
		Content: []byte(""),
		Error:   nil,
	})

	ad := keyfetcher.ActionDetail{
		Action: "FetchLicenseTypeRestricted",
		ResponsePathMap: map[string]string{
			"trial":          "trial_restriction_message",
			"free":           "free_restriction_message",
			"trial_and_free": "only_commercial_allowed_message",
		},
	}
	out := ad.PerformInteraction()
	if out != "free_restriction_message" {
		t.Errorf("expected the license type restriction to be %s, got %s", "free_restriction_message", out)
	}
}

func loadInteractions() map[string]keyfetcher.ActionDetail {
	var intr keyfetcher.Interaction
	yaml.Unmarshal([]byte(YAML_DATA), &intr)

	return intr.Actions
}

func readFromSTDOUT(function actionFunction) (string, string) {
	originalStdout := os.Stdout
	r, w, _ := os.Pipe()
	os.Stdout = w

	output := function()

	w.Close()
	os.Stdout = originalStdout

	var buf bytes.Buffer
	io.Copy(&buf, r)

	return buf.String(), output
}

func mockAPIResponse(mockResponse string, status int) *httptest.Server {
	mockServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(status)
		w.Write([]byte(mockResponse))
	}))
	setConfig(mockServer.URL)
	return mockServer
}

func setConfig(url string) {
	config.NewConfig(&config.LicenseConfig{
		ProductName:      "Workstation",
		EntitlementID:    "workstation-1234",
		LicenseServerURL: url,
		ExecutableName:   "test",
	})
}
