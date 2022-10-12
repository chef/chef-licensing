require_relative "air_gap/ping"
require_relative "air_gap/environment"
require_relative "air_gap/argument"
require_relative "air_gap/exception"
require_relative "config"

module ChefLicensing

  def self.air_gap_mode_enabled?
    license_server_version_url = ChefLicensing::Config::LICENSING_SERVER + "/v1/version"
    @ping_check = AirGap::Ping.new(license_server_version_url)
    @env_check = AirGap::Environment.new(ENV)
    @argv_check = AirGap::Argument.new(ARGV)

    @env_check.verify_env || @argv_check.verify_argv || !@ping_check.verify_ping
  rescue ChefLicensing::AirGapException => exception
    puts exception.message
    exit
  end
end
