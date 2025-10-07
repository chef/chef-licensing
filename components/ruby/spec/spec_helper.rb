require "bundler/setup"
require "tmpdir"
require "fileutils"

# Create a suite-level temporary HOME early so any code executed at
# require-time that consults the user's HOME doesn't accidentally pick up
# a real developer/CI HOME. We use a lightweight suite-level HOME to
# avoid unnecessary temp-dir churn during startup. Some specs still need
# a clean HOME per-example (they create or expect files under HOME); to
# support those we provide a per-example around hook below which swaps
# in a fresh HOME for the duration of the example.
TMP_TEST_HOME = Dir.mktmpdir("chef_licensing_spec_home")
ENV["HOME"] = TMP_TEST_HOME
# On Windows set USERPROFILE as well for early initialization
ENV["USERPROFILE"] = TMP_TEST_HOME if Gem.win_platform?

# Explicitly set the license server used by tests to a stable, test-only
# URL. This prevents tests from accidentally using a developer/CI
# provided value or reading an on-disk persisted value that points at a
# production server. Keep this deterministic to make tests hermetic.
ENV["CHEF_LICENSE_SERVER"] = "https://custom-licensing-server.com/License"
ENV["LICENSE_SERVER"] = "https://custom-licensing-server.com/License"

# Clear any real license key from the environment so tests don't pick up
# developer/CI credentials by accident. This avoids flaky tests where a
# real key would change behavior or reach out to real endpoints.
ENV.delete("CHEF_LICENSE_KEY")

# Require WebMock before requiring the library so that any HTTP client
# initialization that runs during require-time (for example middleware
# setup that probes a host) is intercepted. Requiring WebMock early is
# the simplest way to guarantee no accidental real HTTP connections
# happen while the test harness initializes.
require "webmock/rspec"
require "chef-licensing"

RSpec.configure do |config|
  # We set a suite-level TMP_TEST_HOME above to keep startup fast and to
  # prevent require-time code from touching a real HOME. Some specs,
  # however, depend on a clean HOME per-example to test file persistence
  # and migrations under the user's home directory. To keep those specs
  # hermetic we swap in a fresh HOME for each example using this around
  # hook. This balances performance (single suite-level HOME) with test
  # correctness for file-based scenarios.
  config.around(:each) do |example|
    original_home = ENV["HOME"]
    original_userprofile = ENV["USERPROFILE"]
    tmp_home = Dir.mktmpdir("chef_licensing_spec_example_home")
    ENV["HOME"] = tmp_home
    ENV["USERPROFILE"] = tmp_home if Gem.win_platform?
    begin
      example.run
    ensure
      ENV["HOME"] = original_home
      ENV["USERPROFILE"] = original_userprofile
      FileUtils.remove_entry_secure(tmp_home) if ::File.exist?(tmp_home)
    end
  end

  # Clear cached configuration in the library before each example to avoid
  # state leaking between tests. Many specs mutate `ChefLicensing::Config`
  # (for example set a license_server_url or change logging/output) and
  # rely on a clean slate. Reset only known, writable attributes here as
  # a best-effort approach; this keeps examples deterministic without
  # tightly coupling to private internals.
  config.before(:each) do
    if defined?(ChefLicensing::Config)
      begin
        ChefLicensing::Config.license_server_url = nil
        ChefLicensing::Config.license_server_url_check_in_file = false
        ChefLicensing::Config.logger = nil
        ChefLicensing::Config.output = nil
        ChefLicensing::Config.make_licensing_optional = false
        ChefLicensing::Config.is_local_license_service = nil
        ChefLicensing::Config.chef_entitlement_id = nil
        ChefLicensing::Config.chef_product_name = nil
        ChefLicensing::Config.chef_executable_name = nil
      rescue StandardError
        # best-effort reset; if some writers are missing ignore and continue
      end
    end
  end

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!
  require "fileutils"

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.exclude_pattern = "./vendor/**/*_spec.rb"
end

# This is required when mocked down key pressed in tui_engine_spec.rb
class StringIO
  def wait_readable(*)
    true
  end
end
