require "net/ping"
require_relative "air_gap/ping"
require_relative "air_gap/environment"
require_relative "air_gap/argument"

module ChefLicensing
  class AirGap

    # TODO: Check URL for public licensing server
    LICENSE_SERVER_URL = "progress.com".freeze

    def initialize
      @ping_check = AirGap::Ping.new(LICENSE_SERVER_URL)
      @env_check = AirGap::Environment.new(ENV)
      @argv_check = AirGap::Argument.new(ARGV)
    end

    def check
      @env_check.verify_env
      @argv_check.verify_argv
      @ping_check.verify_ping
    rescue AirGapException => exception
      puts exception.message
      # TODO: Exit with some code
      exit
    end

    class AirGapException < RuntimeError
    end
  end
end
