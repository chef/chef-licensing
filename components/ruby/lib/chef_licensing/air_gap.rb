require_relative "air_gap/ping"
require_relative "air_gap/environment"
require_relative "air_gap/argument"

module ChefLicensing
  class AirGap

    # TODO: Check URL for public licensing server
    LICENSE_SERVER_URL = "https://licensing-acceptance.chef.co/".freeze

    def self.air_gap_enabled?
      @ping_check = AirGap::Ping.new(LICENSE_SERVER_URL)
      @env_check = AirGap::Environment.new(ENV)
      @argv_check = AirGap::Argument.new(ARGV)
      @env_check.verify_env || @argv_check.verify_argv || !@ping_check.verify_ping
    rescue AirGapException => exception
      puts exception.message
      # TODO: Exit with some code
      exit
    end

    class AirGapException < RuntimeError
    end
  end
end
