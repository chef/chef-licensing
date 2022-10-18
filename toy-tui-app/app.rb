# =========== IMPORTANT =========== #
# This file should be removed once the code is reviewed.
# Execute `ruby app.rb` to see the prompts of tui_engine.
# ================================ #

require_relative "../components/ruby/lib/chef_licensing/license_key_fetcher"
require 'logger'

config = {
  logger: Logger.new(STDERR),
  input: STDIN,
  output: STDOUT,
}

# It says cannot load license_key_fetcher when reached in license_key_fetcher/file.rb due to require
license_acceptor_output = ChefLicensing::LicenseKeyFetcher.fetch_and_persist(config)
