# This file is just used as a load point for component that load configuration.
require_relative "license_server_url"

# TODO: Remove above lines once we are ready to ship this component

require "singleton" unless defined?(Singleton)
require "logger"
require_relative "config_fetcher/arg_fetcher"
require_relative "config_fetcher/env_fetcher"

# TODO: Find a better way to do ping check
require_relative "air_gap_detection/ping"

module ChefLicensing
  class Config
    include Singleton

    attr_reader :license_server_url, :license_server_api_key, :logger, :air_gap_status, :arg_fetcher, :env_fetcher

    # A simple semaphore lock for mutually exclusive access to some shared resource.
    @instance_mutex = Mutex.new

    def initialize(opts = {})
      @arg_fetcher = ChefLicensing::ArgFetcher.new(opts[:cli_args] || ARGV)
      @env_fetcher = ChefLicensing::EnvFetcher.new(opts[:env_vars] || ENV)
      @logger = opts[:logger] || set_default_logger
      @license_server_api_key = set_license_server_api_key
      @license_server_url = set_license_server_url
    end

    # The static method that controls the access to the singleton instance.
    # TODO: Learn more about this
    def self.instance(opts = {})
      return @instance if @instance

      @instance_mutex.synchronize do
        @instance ||= new(opts)
      end
      @instance
    end

    def air_gap_detected?
      return @air_gap_status unless @air_gap_status.nil?

      # TODO: Find a better way to do ping check
      ping_check = AirGapDetection::Ping.new(license_server_url)
      @air_gap_status = arg_fetcher.fetch_value("--airgap", :boolean) ||
        env_fetcher.fetch_value("CHEF_AIR_GAP", :boolean) ||
        ping_check.detected?
    end

    private

    def set_license_server_url
      @arg_fetcher.fetch_value("--chef-license-server", :string) || @env_fetcher.fetch_value("CHEF_LICENSE_SERVER", :string)
    end

    def set_license_server_api_key
      @arg_fetcher.fetch_value("--chef-license-server-api-key", :string) || @env_fetcher.fetch_value("CHEF_LICENSE_SERVER_API_KEY", :string)
    end

    def set_default_logger
      logger = Logger.new(STDERR)
      logger.level = Logger::INFO
      logger
    end
  end
end
