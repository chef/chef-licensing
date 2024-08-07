package api_test

import (
	"net/http"
	"testing"

	"github.com/chef/chef-licensing/components/go/pkg/api"
)

const VALID_RESPONSE = `
	{
		"data": true,
		"message": "License Id is valid",
		"status_code": 200
	}
`
const INVALID_RESPONSE = `
	{
		"data": false,
		"message": "license not found",
		"status_code": 400
	}
`

func TestValidateLicenseSuccess(t *testing.T) {
	mockServer := MockAPIResponse(VALID_RESPONSE, http.StatusOK)
	defer mockServer.Close()

	client := api.NewClient()

	valid, err := client.ValidateLicenseAPI("key-123456")
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	_, ok := interface{}(valid).(bool)
	if !ok {
		t.Errorf("expected the response to be of type bool, got %T", valid)
	}

	if !valid {
		t.Errorf("expected the api to return %v, got %v", true, valid)
	}
}

func TestValidateLicenseFailure(t *testing.T) {
	mockServer := MockAPIResponse(INVALID_RESPONSE, http.StatusBadRequest)
	defer mockServer.Close()

	client := api.NewClient()
	valid, err := client.ValidateLicenseAPI("key-123456", true)
	if err == nil {
		t.Fatalf("expected errors, got %v", err)
	}

	if valid {
		t.Errorf("expected the response to be %v, got %v", false, valid)
	}
}
