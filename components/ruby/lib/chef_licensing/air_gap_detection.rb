require_relative "air_gap_detection/ping"
require_relative "air_gap_detection/environment"
require_relative "air_gap_detection/argument"
require_relative "config"

module ChefLicensing

  def self.air_gap_detected?
    @env_check = AirGapDetection::Environment.new(ENV)
    @argv_check = AirGapDetection::Argument.new(ARGV)
    @ping_check = AirGapDetection::Ping.new(ChefLicensing::Config.licensing_server)

    @env_check.detected? || @argv_check.detected? || @ping_check.detected?
  end
end
