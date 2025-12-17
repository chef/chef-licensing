package api_test

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/chef/chef-licensing/components/go/pkg/api"
	"github.com/chef/chef-licensing/components/go/pkg/config"
)

func TestNewClient(t *testing.T) {
	setConfig()

	client := api.NewClient()
	if client.URL != "https://testing.license.chef.io" {
		t.Errorf("expected BaseURL to be %s, got %s", "https://testing.license.chef.io", client.URL)
	}
	if client.BaseURL() != "https://testing.license.chef.io/v1/" {
		t.Errorf("expected BaseURL to be %s, got %s", "https://testing.license.chef.io/v1/", client.BaseURL())
	}
	if client.HTTPClient == nil {
		t.Error("expected HTTPClient to be initialized, got nil")
	}
	_, ok := interface{}(client.HTTPClient).(*http.Client)
	if !ok {
		t.Error("expected HTTPClient to be of type *http.Client")
	}
}

func TestGetClient(t *testing.T) {
	setConfig()

	client1 := api.GetClient()
	client2 := api.GetClient()

	if client1 != client2 {
		t.Error("client created multiple times")
	}
}

func TestSetHeader(t *testing.T) {
	setConfig()
	client := api.GetClient()
	client.SetHeader("testkey", "testval")
	if client.Headers["testkey"] != "testval" {
		t.Errorf("expected to set the headers %s:%s, but failed: %v", "testkey", "testval", client.Headers)
	}
}

func MockAPIResponse(mockResponse string, status int) *httptest.Server {
	mockServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(status)
		_, _ = w.Write([]byte(mockResponse))
	}))
	setConfig(mockServer.URL)

	return mockServer
}

func setConfig(urls ...string) {
	var url string
	if len(urls) > 0 {
		url = urls[0]
	} else {
		url = "https://testing.license.chef.io"
	}
	config.NewConfig(&config.LicenseConfig{
		ProductName:      "Workstation",
		EntitlementID:    "workstation-1234",
		LicenseServerURL: url,
		ExecutableName:   "test",
	})
}
