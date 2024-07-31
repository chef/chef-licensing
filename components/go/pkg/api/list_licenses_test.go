package api_test

import (
	"fmt"
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
	fmt.Println(resp, err)
	t.Log(resp, err)
	t.Error("test")
}

func TestListLicensesAPIFailure(t *testing.T) {
	mockServer := MockAPIResponse(LIST_INVALID_RESPONSE, http.StatusNotFound)
	defer mockServer.Close()

	client := api.NewClient()
	resp, err := client.ListLicensesAPI()
	fmt.Println(resp, err)
	t.Log(resp, err)
	t.Error("test")
}
