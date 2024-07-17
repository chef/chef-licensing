package api_test

import (
	"net/http"
	"testing"

	"github.com/chef/chef-licensing/components/go/pkg/api"
)

const SOFTWARE_ENTITLEMENT_VALID_RESPONSE = `
	{
		"data": {
			"key-123456": [
				{
					"name": "Workstation",
					"id": "workstation-12345",
					"measure": "node",
					"limit": 10,
					"grace": {
						"limit": 0,
						"duration": 0
					},
					"period": {
						"start": "2024-06-26",
						"end": "2024-07-26"
					}
				}
			]
		},
		"status": 200
	}
`

func TestGetAllEntitlementsByLisenceID(t *testing.T) {
	mockServer := MockAPIResponse(SOFTWARE_ENTITLEMENT_VALID_RESPONSE, http.StatusOK)
	defer mockServer.Close()

	apiClient := api.NewClient()

	licenseID := "key-123456"
	data, err := apiClient.GetAllEntitlementsByLisenceID([]string{licenseID})
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if data == nil {
		t.Error("expected entitlements, got nil")
	}
}
