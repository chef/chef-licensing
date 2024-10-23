package main

import (
	"fmt"

	cheflicensing "github.com/chef/chef-licensing/components/go/pkg"
	"github.com/chef/chef-licensing/components/go/pkg/config"
)

func main() {
	config.SetConfig("Workstation", "x6f3bc76-a94f-4b6c-bc97-4b7ed2b045c0", "https://licensing-acceptance.chef.co/License", "chef")
	fmt.Println(cheflicensing.FetchAndPersist())
}
