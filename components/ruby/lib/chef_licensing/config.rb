# This file is just used as a load point for component that load configuration.
require_relative "license_server_url"

# Remove above lines once we are ready to ship this component

require_relative "config_fetcher/arg_fetcher"
require_relative "config_fetcher/env_fetcher"

module ChefLicensing
  class Config

    class << self

      def licensing_server_url
        opt_fetcher = ChefLicensing::ArgFetcher::String.new("license-server-url")
        env_fetcher = ChefLicensing::EnvFetcher::String.new("CHEF_LICENSE_SERVER_URL")
        @license_server_url ||= opt_fetcher.value || env_fetcher.value || ChefLicensing::DEFAULT_LICENSE_SERVER_URL
      end

      def license_server_api_key
        opt_fetcher = ChefLicensing::ArgFetcher::String.new("license-server-api-key")
        env_fetcher = ChefLicensing::EnvFetcher::String.new("CHEF_LICENSE_SERVER_API_KEY")
        @license_server_api_key ||= opt_fetcher.value || env_fetcher.value
      end

      def logger
        # TODO: Initialize logger from the logger class which is yet to be implemented
      end

      def air_gap_detected?
        # TODO: Decide how would we want implement the ping strategy?
      end
    end

    DEFAULT_LICENSE_SERVER_URL = "https://licensing.chef.co/License".freeze
  end
end
