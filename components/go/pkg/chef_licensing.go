package cheflicensing

// import keyfetcher "github.com/chef/go-libs/chef_licensing/key_fetcher"
import keyfetcher "github.com/chef/chef-licensing/components/go/pkg/key_fetcher"

func FetchAndPersist() []string {
	return keyfetcher.GlobalFetchAndPersist()
}