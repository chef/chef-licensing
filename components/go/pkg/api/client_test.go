package api_test

import (
	"bytes"
	"errors"
	"io"
	"log"
	"net/http"
	"strings"
	"testing"

	"github.com/chef/chef-licensing/components/go/pkg/api"
)

type failingCloseBody struct {
	io.Reader
}

func (failingCloseBody) Close() error {
	return errors.New("close failed")
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(req *http.Request) (*http.Response, error) {
	return f(req)
}

const VALID_CLIENT = `
	{
		"data": {
			"client": {
				"license": "free",
				"status": "Active",
				"changesTo": "Expired",
				"changesOn": "2025-06-10T00:00:00Z",
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
const INVALID_CLIENT = `
	{
		"data": false,
		"message": "invalid licenseId",
		"status_code": 400
	}
`

func TestGetLicneseClient(t *testing.T) {
	mockServer := MockAPIResponse(VALID_CLIENT, http.StatusOK)
	defer mockServer.Close()

	client := api.NewClient()

	licenseClient, err := client.GetLicenseClient([]string{"key-123"})
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	t.Log(licenseClient)

	_, ok := interface{}(licenseClient).(*api.LicenseClient)
	if !ok {
		t.Errorf("expected the response to be of type *api.LicenseClient, got %T", licenseClient)
	}

	if licenseClient.LicenseType != "free" {
		t.Errorf("expected the license type to be free, got %v", licenseClient.LicenseType)
	}
	if licenseClient.IsCommercial() {
		t.Errorf("expected the license not to be commerical, got %v", licenseClient.LicenseType)
	}
	if !licenseClient.IsFree() {
		t.Errorf("expected the license to be free, got %v", licenseClient.LicenseType)
	}
	if licenseClient.Status != "Active" {
		t.Errorf("expected the status to be Active, got %v", licenseClient.Status)
	}
	if licenseClient.IsExpiringOrExpired() {
		t.Error("expected the it be expiring or expired")
	}
	if licenseClient.IsExhausted() {
		t.Errorf("expected not to be exhausted, got %v", licenseClient.Status)
	}

}

func TestFailedLicenseClient(t *testing.T) {
	mockServer := MockAPIResponse(INVALID_CLIENT, http.StatusBadRequest)
	defer mockServer.Close()

	client := api.NewClient()

	licenseClient, err := client.GetLicenseClient([]string{"key-123"}, true)
	if err == nil {
		t.Fatalf("expected the api to fail, but succeeded and returned %v", licenseClient)
	}
	if err.Error() != "invalid licenseId" {
		t.Fatalf("expected `invalid licenseId` error, got %s", err.Error())
	}
}

func TestResponseBodyCloseErrorIsLogged(t *testing.T) {
	tests := []struct {
		name string
		body string
		call func(*api.APIClient) error
	}{
		{"client", VALID_CLIENT, func(c *api.APIClient) error {
			_, err := c.GetLicenseClient([]string{"key-123"})
			return err
		}},
		{"list", `{"data":[]}`, func(c *api.APIClient) error {
			_, err := c.ListLicensesAPI()
			return err
		}},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var output bytes.Buffer
			originalOutput := log.Writer()
			log.SetOutput(&output)
			t.Cleanup(func() { log.SetOutput(originalOutput) })

			client := &api.APIClient{
				URL: "https://example.com",
				HTTPClient: &http.Client{Transport: roundTripFunc(func(*http.Request) (*http.Response, error) {
					return &http.Response{StatusCode: http.StatusOK, Body: failingCloseBody{strings.NewReader(tt.body)}}, nil
				})},
			}
			setConfig()
			if err := tt.call(client); err != nil {
				t.Fatalf("request failed: %v", err)
			}
			if !strings.Contains(output.String(), "Failed to close response body: close failed") {
				t.Errorf("expected close error to be logged, got %q", output.String())
			}
		})
	}
}
