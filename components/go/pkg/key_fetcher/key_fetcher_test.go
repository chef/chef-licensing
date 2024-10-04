package keyfetcher_test

import (
	"testing"

	keyfetcher "github.com/chef/chef-licensing/components/go/pkg/key_fetcher"
)

func TestValidateKeyFormat(t *testing.T) {
	if keyfetcher.ValidateKeyFormat("invalid-key") {
		t.Errorf("expected %v to be invalid key", "invalid-key")
	}

	if !keyfetcher.ValidateKeyFormat("tmns-b887451a-625d-4033-8259-108d2364c401-4278") {
		t.Errorf("expected %v to be a valid license-key", "tmns-b887451a-625d-4033-8259-108d2364c401-4278")
	}

	if !keyfetcher.ValidateKeyFormat("5fd13cca-14b7-42b9-ad47-d52a0630c1ae") {
		t.Errorf("expected %v to be a valid license-key", "5fd13cca-14b7-42b9-ad47-d52a0630c1ae")
	}
}
