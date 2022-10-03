# This file should be removed once the code is reviewed.
# Execute this file with `ruby app.rb` to see the prompts of tui_engine.

require_relative "../components/ruby/lib/chef_licensing/license_key_fetcher"
require 'logger'

license_acceptor_output = ChefLicensing::LicenseKeyFetcher.fetch_and_persist("InSpec", "5.0.0", {logger: Logger.new(STDOUT)})
