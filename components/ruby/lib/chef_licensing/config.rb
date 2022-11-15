# This file is just used as a load point for component that load configuration.
require_relative "license_server_url"

# TODO: Remove above lines once we are ready to ship this component

require_relative "config_fetcher/arg_fetcher"
require_relative "config_fetcher/env_fetcher"

# TODO: Find a better way to do ping check
require_relative "air_gap_detection/ping"

require_relative "chef_licensing_logger"

module ChefLicensing
  class Config

    class << self

      attr_writer :license_server_url, :license_server_api_key, :logger, :air_gap_detected

      def license_server_url
        # TODO: Do we keep the ENV name as CHEF_LICENSE_SERVER
        # or do we change it to CHEF_LICENSE_SERVER_URL to keep it consistent with the method name?
        arg_fetcher = ChefLicensing::ArgFetcher::String.new("license-server-url")
        env_fetcher = ChefLicensing::EnvFetcher::String.new("CHEF_LICENSE_SERVER_URL")
        @license_server_url ||= arg_fetcher.value || env_fetcher.value || ChefLicensing::Config::DEFAULT_LICENSE_SERVER_URL
      end

      def license_server_api_key
        arg_fetcher = ChefLicensing::ArgFetcher::String.new("license-server-api-key")
        env_fetcher = ChefLicensing::EnvFetcher::String.new("CHEF_LICENSE_SERVER_API_KEY")
        @license_server_api_key ||= arg_fetcher.value || env_fetcher.value
      end

      def logger
        @logger ||= ChefLicensing::ChefLicensingLogger.new
      end

      def air_gap_detected?
        arg_fetcher = ChefLicensing::ArgFetcher::Boolean.new("airgap")
        env_fetcher = ChefLicensing::EnvFetcher::Boolean.new("CHEF_AIR_GAP")

        # TODO: Find a better way to do ping check
        ping_check = AirGapDetection::Ping.new(license_server_url)
        @air_gap_detected ||= arg_fetcher.value || env_fetcher.value || ping_check.detected?
      end
    end

    DEFAULT_LICENSE_SERVER_URL = "https://licensing-acceptance.chef.co/License".freeze
  end
end
