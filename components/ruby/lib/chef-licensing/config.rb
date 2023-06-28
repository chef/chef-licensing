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
      attr_writer :license_server_url, :logger, :output, :license_server_url_check_in_file

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
        return @logger if @logger

        @logger = Logger.new(STDERR)
        @logger.level = Logger::INFO
        @logger
      end

      def output
        @output ||= STDOUT
      end
    end
  end
end
