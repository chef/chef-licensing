package keyfetcher_test

import (
	"net/http"
	"testing"

	keyfetcher "github.com/chef/chef-licensing/components/go/pkg/key_fetcher"
)

const DESCRIBE_API_RESPONSE = `
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

func TestPrintLicenseKeyOverview(t *testing.T) {
	mockServer := mockAPIResponse(DESCRIBE_API_RESPONSE, http.StatusOK)
	defer mockServer.Close()

	keyfetcher.PrintLicenseKeyOverview([]string{"key-123456"})
}
