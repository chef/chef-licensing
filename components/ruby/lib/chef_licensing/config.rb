# This file is just used as a load point for component that load configuration.
require_relative "license_server_url"

# TODO: Remove above lines once we are ready to ship this component

require "singleton" unless defined?(Singleton)
require_relative "config_fetcher/arg_fetcher"
require_relative "config_fetcher/env_fetcher"

# TODO: Find a better way to do ping check
require_relative "air_gap_detection/ping"

module ChefLicensing
  class Config
    include Singleton

    attr_reader :license_server_url, :license_server_api_key, :logger, :status

    def initialize(logger = nil)
      @logger = logger || Logger.new(STDERR)
      @license_server_api_key = set_license_server_api_key
      @license_server_url = set_license_server_url
    end

    def air_gap_detected?
      return @status unless @status.nil?

      arg_fetcher = ChefLicensing::ArgFetcher::Boolean.new("airgap")
      env_fetcher = ChefLicensing::EnvFetcher::Boolean.new("CHEF_AIR_GAP")

      # TODO: Find a better way to do ping check
      ping_check = AirGapDetection::Ping.new(license_server_url)

      @status = arg_fetcher.value || env_fetcher.value || ping_check.detected?
    end

    private

    def set_license_server_url
      arg_fetcher = ChefLicensing::ArgFetcher::String.new("--chef-license-server")
      env_fetcher = ChefLicensing::EnvFetcher::String.new("CHEF_LICENSE_SERVER")
      arg_fetcher.value || env_fetcher.value
    end

    def set_license_server_api_key
      arg_fetcher = ChefLicensing::ArgFetcher::String.new("--chef-license-server-api-key")
      env_fetcher = ChefLicensing::EnvFetcher::String.new("CHEF_LICENSE_SERVER_API_KEY")
      arg_fetcher.value || env_fetcher.value
    end
  end
end
