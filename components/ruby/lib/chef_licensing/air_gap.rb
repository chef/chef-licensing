require "net/ping"

module ChefLicensing
  class AirGap
    # TODO: Check URL for public chef server
    CHEF_SERVER_URL = "progress.com".freeze

    attr_reader :status
    def self.air_gapped_env?
      raise AirGapEnvException, "AIR_GAP environment variable is enabled." if ENV["AIR_GAP"] == "enabled"

      raise AirGapFlagException, "--airgap flag is enabled." if ARGV.include?("--airgap")

      raise AirGapPingException, "Unable to ping public chef server.\nPlease check your internet connectivity." unless reachable?(CHEF_SERVER_URL)

      false
    rescue AirGapEnvException, AirGapFlagException, AirGapPingException => exception
      puts exception.message
      # TODO: Exit with some code
      exit
    end

    def self.reachable?(host)
      check = Net::Ping::External.new(host)
      check.ping?
    end

    class AirGapEnvException < RuntimeError
    end

    class AirGapFlagException < RuntimeError
    end

    class AirGapPingException < RuntimeError
    end
  end
end
