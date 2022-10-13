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

  config.exclude_pattern = "./vendor/**/*_spec.rb"
end

ENV["CHEF_LICENSE_SERVER"] = "http://localhost-license-server/License"

# This is required when mocked down key pressed in tui_engine_spec.rb
class StringIO 
  def wait_readable(*) 
    true 
  end 
end 
