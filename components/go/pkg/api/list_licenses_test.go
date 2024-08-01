package api_test

import (
	"net/http"
	"testing"

	"github.com/chef/chef-licensing/components/go/pkg/api"
)

const LIST_VALID_RESPONSE = `
	{
		"data": ["key-123"],
		"message": "",
		"status_code": 200
	}
`
const LIST_INVALID_RESPONSE = `
	{
		"data": null,
		"message": "You are not authorized to access this resource",
		"status_code": 404
	}
`

func TestListLicensesAPISuccess(t *testing.T) {
	mockServer := MockAPIResponse(LIST_VALID_RESPONSE, http.StatusOK)
	defer mockServer.Close()

	client := api.NewClient()

	resp, err := client.ListLicensesAPI()
	if err != nil {
		t.Errorf("expected the client to not return error, got %v", err)
	}
	if resp[0] != "key-123" {
		t.Errorf("expected the api to return %v, got %v", "key-123", resp[0])
	}
}

func TestListLicensesAPIFailure(t *testing.T) {
	mockServer := MockAPIResponse(LIST_INVALID_RESPONSE, http.StatusNotFound)
	defer mockServer.Close()

	client := api.NewClient()
	_, err := client.ListLicensesAPI()
	if err == nil {
		t.Errorf("expected the api to return error, got none")
	}
	if err.Error() != "not found" {
		t.Errorf("expected the api to return <%v>, got <%v>", "not found", err.Error())
	}
}
