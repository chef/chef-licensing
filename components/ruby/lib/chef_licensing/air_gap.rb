require_relative "air_gap/ping"
require_relative "air_gap/environment"
require_relative "air_gap/argument"
require_relative "air_gap/exception"
require_relative "config"

module ChefLicensing

  def self.air_gap_mode_enabled?
    @ping_check = AirGap::Ping.new(ChefLicensing.license_server_url)
    @env_check = AirGap::Environment.new(ENV)
    @argv_check = AirGap::Argument.new(ARGV)

    @env_check.enabled? || @argv_check.enabled? || @ping_check.enabled?
  rescue ChefLicensing::AirGapException => exception
    puts exception.message
    exit
  end
end
