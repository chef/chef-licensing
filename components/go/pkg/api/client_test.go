package api_test

import (
	"net/http"
	"testing"

	"github.com/chef/chef-licensing/components/go/pkg/api"
)

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
