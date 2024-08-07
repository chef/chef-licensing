package config_test

import (
	"testing"

	"github.com/chef/chef-licensing/components/go/pkg/config"
)

func TestNewConfig(t *testing.T) {
	c := config.LicenseConfig{
		ProductName:      "testing",
		EntitlementID:    "testing-1234",
		LicenseServerURL: "https://testing.license.chef.io",
		ExecutableName:   "test",
	}
	config.NewConfig(&c)
	assertions(t)
}

func TestSetConfig(t *testing.T) {
	config.SetConfig("testing", "testing-1234", "https://testing.license.chef.io", "test")

	assertions(t)
}

func assertions(t *testing.T) {
	conf := config.GetConfig()
	if conf.ProductName != "testing" {
		t.Errorf("expected the productName to be %v, got %v", "testing", conf.ProductName)
	}
	if conf.EntitlementID != "testing-1234" {
		t.Errorf("expected the EntitlementID to be %v, got %v", "testing-1234", conf.EntitlementID)
	}
	if conf.ExecutableName != "test" {
		t.Errorf("expected the ExecutableName to be %v, got %v", "test", conf.ExecutableName)
	}
	if conf.LicenseServerURL != "https://testing.license.chef.io" {
		t.Errorf("expected the LicenseServerURL to be %v, got %v", "https://testing.license.chef.io", conf.LicenseServerURL)
	}
}
