package main

import (
	"fmt"

	cheflicensing "github.com/chef/chef-licensing/components/go/pkg"
	licenseConfig "github.com/chef/chef-licensing/components/go/pkg/config"
)

func main() {
	licenseConfig.SetConfig("Workstation", "x6f3bc76-a94f-4b6c-bc97-4b7ed2b045c0", "https://licensing-acceptance.chef.co", "chef")
	fmt.Println(cheflicensing.FetchAndPersist())
	// free-0b54aca5-5170-4611-a66e-5835f387fbd9-1922
	// tmns-b887451a-625d-4033-8259-108d2364c401-4278

	// c := api.NewAPIClient()
	// key := "free-0b54aca5-5170-4611-a66e-5835f387fbd9-1922"
	// fmt.Println(c)
	// rep, err := c.LicenseClientLicense("x6f3bc76-a94f-4b6c-bc97-4b7ed2b045c0", &models.LicenseClientLicenseOpt{LicenseIds: &key})
	// fmt.Println(rep, err)
}
