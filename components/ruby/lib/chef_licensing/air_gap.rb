require_relative "air_gap/ping"
require_relative "air_gap/environment"
require_relative "air_gap/argument"
require_relative "air_gap/exception"

module ChefLicensing
  # TODO: Check URL for public licensing server
  LICENSE_SERVER_URL = "https://licensing-acceptance.chef.co/".freeze

  def self.air_gap_mode_enabled?
    @ping_check = AirGap::Ping.new(LICENSE_SERVER_URL)
    @env_check = AirGap::Environment.new(ENV)
    @argv_check = AirGap::Argument.new(ARGV)

    @env_check.verify_env || @argv_check.verify_argv || !@ping_check.verify_ping
  rescue ChefLicensing::AirGapException => exception
    puts exception.message
    # TODO: Exit with some code
    exit
  end
end
