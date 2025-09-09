require "singleton" unless defined?(Singleton)
require "logger"
require_relative "config_fetcher/arg_fetcher"
require_relative "config_fetcher/env_fetcher"
require_relative "license_key_fetcher/file"
require_relative "log"

# Config class handles all configuration related to chef-licensing
# Values can be set via block, environment variable or command line argument

# Licensing service detection
require_relative "licensing_service/local"

module ChefLicensing
  class Config
    class << self
      attr_writer :license_server_url, :logger, :output, :license_server_url_check_in_file, :license_add_command, :license_list_command

      # is_local_license_service is used by context class
      attr_accessor :is_local_license_service, :chef_entitlement_id, :chef_product_name, :chef_executable_name

      def license_server_url(opts = {})
        return @license_server_url if @license_server_url && @license_server_url_check_in_file

        license_server_url_from_system = ChefLicensing::ArgFetcher.fetch_value("--chef-license-server", :string) || ChefLicensing::EnvFetcher.fetch_value("CHEF_LICENSE_SERVER", :string)
        @license_server_url = ChefLicensing::LicenseKeyFetcher::File.fetch_or_persist_url(@license_server_url, license_server_url_from_system, opts)
        @license_server_url_check_in_file = true
        @license_server_url
      end

      def logger
        # If no log level flags are set and we have a cached logger (like Inspec::Log), use it as-is
        return @logger if @logger && !log_level_flags_present?

        # If log level flags are present, configure the logger with determined level
        @logger = ChefLicensing::Log
        @logger.level = determine_log_level
        @logger
      end

      def determine_log_level
        log_level_string = get_log_level_from_flags

        valid = %w{trace debug info warn error fatal}

        if valid.include?(log_level_string)
          log_level = log_level_string
        else
          log_level = "info"
        end

        Mixlib::Log.const_get(log_level.upcase)
      end

      def output
        @output ||= STDOUT
      end

      def license_add_command
        @license_add_command ||= "license add"
      end

      def license_list_command
        @license_list_command ||= "license list"
      end

      private

      def log_level_flags_present?
        !get_log_level_from_flags.nil?
      end

      def get_log_level_from_flags
        ChefLicensing::ArgFetcher.fetch_value("--log-level", :string) ||
        ChefLicensing::ArgFetcher.fetch_value("--chef-log-level", :string) ||
        ChefLicensing::EnvFetcher.fetch_value("LOG_LEVEL", :string) ||
        ChefLicensing::EnvFetcher.fetch_value("CHEF_LOG_LEVEL", :string)
      end
    end
  end
end
