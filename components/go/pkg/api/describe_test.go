package api_test

import (
	"net/http"
	"testing"

	"github.com/chef/chef-licensing/components/go/pkg/api"
	"github.com/chef/chef-licensing/components/go/pkg/config"
)

const VALID_DESCRIBE = `
	{
		"data": {
			"license": [
				{
					"licenseKey": "key-123456",
					"serialNumber": "NA",
					"licenseType": "trial",
					"name": "Lorem Ipsum",
					"start": "2024-05-30T00:00:00Z",
					"end": "2024-06-29T00:00:00Z",
					"status": "Active",
					"limits": [
						{
							"software": "Workstation",
							"id": "workstation-1234",
							"amount": 10,
							"measure": "node",
							"used": 0,
							"status": "Active"
						}
					]
				}
			],
			"Assets": null,
			"Software": [
				{
					"id": "workstation-1234",
					"name": "Workstation",
					"entitled": true,
					"from": [
						{
							"license": "key-123456",
							"status": "Active"
						}
					]
				}
			],
			"Features": [
				{
					"id": "feature-123",
					"name": "Inspec-Parallel",
					"entitled": true,
					"from": [
						{
							"license": "key-123456",
							"status": "Active"
						}
					]
				}
			],
			"Services": null
		},
		"message": "",
		"status": 200
	}
`
const INVALID_DESCRIBE = `
	{
		"data": {
			"license": [
				{
					"licenseKey": "key-654321",
					"serialNumber": "Invalid",
					"licenseType": "Invalid",
					"name": "",
					"start": "0001-01-01T00:00:00Z",
					"end": "0001-01-01T00:00:00Z",
					"status": "Invalid",
					"limits": null
				}
			],
			"Assets": null,
			"Software": null,
			"Features": null,
			"Services": null
		},
		"message": "",
		"status": 200
	}
`

func TestGetLicenseDescribe(t *testing.T) {
	mockServer := MockAPIResponse(VALID_DESCRIBE, http.StatusOK)
	defer mockServer.Close()

	apiClient := api.NewClient()

	licenseID := "key-123456"
	describe, err := apiClient.GetLicenseDescribe([]string{licenseID})
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	t.Log(describe)
	_, ok := interface{}(describe).(*api.LicenseDescribe)
	if !ok {
		t.Errorf("expected the response to be of type *api.LicenseDescribe, got %T", describe)
	}
	if describe.Licenses[0].LicenseKey != licenseID {
		t.Errorf("expected the licensekey to be %v, got %v", licenseID, describe.Licenses[0].LicenseKey)
	}
	if len(describe.Softwares) == 0 {
		t.Errorf("expected to return Softwares, got %v", describe.Softwares)
	}
	limit := describe.Licenses[0].Limits[0]
	conf := config.GetConfig()
	if limit.Software != "Workstation" {
		t.Errorf("expected the software to %v, got %v", conf.ProductName, limit.Software)
	}
	if limit.ID != "workstation-1234" {
		t.Errorf("expected the software to %v, got %v", conf.EntitlementID, limit.ID)
	}
}

func TestGetLicenseDescribeFailure(t *testing.T) {
	mockServer := MockAPIResponse(INVALID_DESCRIBE, http.StatusOK)
	defer mockServer.Close()

	apiClient := api.NewClient()

	licenseID := "key-123456"
	describe, err := apiClient.GetLicenseDescribe([]string{licenseID})
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if describe.Licenses[0].LicenseType != "Invalid" {
		t.Errorf("expected the license id to be %v, got %v", "Invalid", describe.Licenses[0].LicenseType)
	}
}
