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
        @chef_entitlement_id ||= ChefLicensing::ArgFetcher.fetch_value("--chef-entitlement-id", :string) || ChefLicensing::EnvFetcher.fetch_value("CHEF_ENTITLEMENT_ID", :string)
      end

      def chef_product_name
        @chef_product_name ||= ChefLicensing::ArgFetcher.fetch_value("--chef-product-name", :string) || ChefLicensing::EnvFetcher.fetch_value("CHEF_PRODUCT_NAME", :string)
      end

      def chef_executable_name
        @chef_executable_name ||= ChefLicensing::ArgFetcher.fetch_value("--chef-executable-name", :string) || ChefLicensing::EnvFetcher.fetch_value("CHEF_EXECUTABLE_NAME", :string)
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
        return @output if @output

        # Check if user wants to write to a file or to stdout
        no_stdout_check = ChefLicensing::ArgFetcher.fetch_value("--chef-license-no-stdout", :boolean) || ChefLicensing::EnvFetcher.fetch_value("CHEF_LICENSE_NO_STDOUT", :boolean)

        unless no_stdout_check
          @output = STDOUT
          return @output
        end

        # Check if user wants to write to a file
        file_path = ChefLicensing::ArgFetcher.fetch_value("--chef-license-output-file", :string) || ChefLicensing::EnvFetcher.fetch_value("CHEF_LICENSE_OUTPUT_FILE", :string)

        # Set the default file path if file path is not provided by the user
        file_path = "~/.chef/output_logs" if file_path.nil? || file_path.empty?

        # Expand the file path
        file_path = File.expand_path(file_path)

        # Create the file if it does not exist
        FileUtils.touch(file_path) unless File.exist?(file_path)

        # Check if the file is writable
        unless File.writable?(file_path)
          @output = StringIO.new
          return @output
        end

        # Open the file in write mode
        @output = File.open(file_path, "w")
        @output
      end
    end
  end
end
