package api_test

import (
	"net/http"
	"testing"

	"github.com/chef/chef-licensing/components/go/pkg/api"
)

const FEATURE_VALID_RESPONSE = `
	{
		"data": {
			"entitled": true,
			"entitledBy": {
				"key-123456": true
			},
			"limits": {}
		},
		"status": 200
	}
`

func TestGetFeatureByName(t *testing.T) {
	mockServer := MockAPIResponse(FEATURE_VALID_RESPONSE, http.StatusOK)
	defer mockServer.Close()

	apiClient := api.NewClient()

	licenseID := "key-123456"
	data, err := apiClient.GetFeatureByName("feature", []string{licenseID})
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	t.Log(data)
	if !data.Entitled {
		t.Errorf("expected entitlement to be %v, got %v", true, data.Entitled)
	}
	if !data.EntitledBy["key-123456"] {
		t.Errorf("expected entitlement to be %v, got %v", true, data.EntitledBy["key-123456"])
	}

}

func TestGetFeatureByGUID(t *testing.T) {
	mockServer := MockAPIResponse(FEATURE_VALID_RESPONSE, http.StatusOK)
	defer mockServer.Close()

	apiClient := api.NewClient()

	licenseID := "key-123456"
	data, err := apiClient.GetFeatureByGUID("feature-123", []string{licenseID})
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	t.Log(data)
	if !data.Entitled {
		t.Errorf("expected entitlement to be %v, got %v", true, data.Entitled)
	}
	if !data.EntitledBy["key-123456"] {
		t.Errorf("expected entitlement to be %v, got %v", true, data.EntitledBy["key-123456"])
	}
}
