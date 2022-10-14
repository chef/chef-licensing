require_relative "air_gap_detection/ping"
require_relative "air_gap_detection/environment"
require_relative "air_gap_detection/argument"
require_relative "air_gap_detection/exception"
require_relative "config"

module ChefLicensing

  def self.air_gap_detected?
    @ping_check = AirGapDetectionDetection::Ping.new(ChefLicensing.license_server_url)
    @env_check = AirGapDetection::Environment.new(ENV)
    @argv_check = AirGapDetection::Argument.new(ARGV)

    @env_check.detected? || @argv_check.detected? || @ping_check.detected?
  rescue ChefLicensing::AirGapDetectionException => exception
    puts exception.message
    exit
  end
end
