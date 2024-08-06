package cheflicensing_test

import (
	"testing"

	cheflicensing "github.com/chef/chef-licensing/components/go/pkg"
	"github.com/chef/chef-licensing/components/go/pkg/config"
)

func TestFetchAndPersist(t *testing.T) {
	config.SetConfig("Workstation", "x6f3bc76-a94f-4b6c-bc97-4b7ed2b045c0", "http://172.19.136.95:8000", "chef")
	cheflicensing.FetchAndPersist()
}
