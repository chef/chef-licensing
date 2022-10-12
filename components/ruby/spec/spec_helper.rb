require "bundler/setup"
require "chef_licensing"
require "webmock/rspec"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    licensing_server_response = {
      status: "success",
      data: [],
    }
    stub_request(:get, "https://localhost-license-server/License")
      .to_return(status: 200, body: licensing_server_response.to_json)

    stub_request(:get, "https://wrong-url.co/")
      .to_return(status: 404, body: "", headers: {})
  end
end

ENV["LICENSING_SERVER"] = "http://localhost-license-server/License"
