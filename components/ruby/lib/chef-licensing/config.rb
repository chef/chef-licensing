require "singleton" unless defined?(Singleton)
require "logger"
require_relative "config_fetcher/arg_fetcher"
require_relative "config_fetcher/env_fetcher"
require_relative "license_key_fetcher/file"

# Config class handles all configuration related to chef-licensing
# Values can be set via block, environment variable or command line argument

# Licensing service detection
require_relative "licensing_service/local"

module ChefLicensing
  class Config
    class << self
      attr_writer :license_server_url, :chef_product_name, :chef_entitlement_id, :logger, :output, :chef_executable_name, :license_server_url_check_in_file

      # Used by context class
      attr_accessor :is_local_license_service

      def license_server_url(opts = {})
        return @license_server_url if @license_server_url && @license_server_url_check_in_file

        license_server_url_from_system = ChefLicensing::ArgFetcher.fetch_value("--chef-license-server", :string) || ChefLicensing::EnvFetcher.fetch_value("CHEF_LICENSE_SERVER", :string)

        @license_server_url = ChefLicensing::LicenseKeyFetcher::File.fetch_or_persist_url(@license_server_url, license_server_url_from_system, opts)
        @license_server_url_check_in_file = true
        @license_server_url
      end

      def chef_entitlement_id
        @chef_entitlement_id
      end

      def chef_product_name
        @chef_product_name
      end

      def chef_executable_name
        @chef_executable_name
      end

      def logger
        return @logger if @logger

        # Supporting both --chef-log-level and --log-level for compatibility with InSpec and to stay aligned with Chef Licensing naming convention
        log_level = ChefLicensing::ArgFetcher.fetch_value("--log-level", :string) || ChefLicensing::EnvFetcher.fetch_value("LOG_LEVEL", :string) ||
          ChefLicensing::ArgFetcher.fetch_value("--chef-log-level", :string) || ChefLicensing::EnvFetcher.fetch_value("CHEF_LOG_LEVEL", :string)
        log_location = ChefLicensing::ArgFetcher.fetch_value("--log-location", :string) || ChefLicensing::EnvFetcher.fetch_value("LOG_LOCATION", :string) ||
          ChefLicensing::ArgFetcher.fetch_value("--chef-log-location", :string) || ChefLicensing::EnvFetcher.fetch_value("CHEF_LOG_LOCATION", :string)

        if log_level.nil? || log_level.empty?
          log_level = Logger::INFO
        else
          unless %w{debug info warn error fatal}.include?(log_level.downcase)
            warn "Invalid log level #{log_level}. Valid log levels are debug, info, warn, error, fatal. Setting log level to info"
            log_level = Logger::INFO
          end
          log_level = Logger.const_get(log_level.upcase)
        end

        log_location = STDERR if log_location.nil? || log_location.empty?

        @logger = Logger.new(log_location)
        @logger.level = log_level
        @logger
      end

      def output
        @output ||= STDOUT
      end
    end
  end
end
