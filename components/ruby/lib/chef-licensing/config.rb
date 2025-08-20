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
      attr_writer :license_server_url, :logger, :output, :license_server_url_check_in_file, :license_add_command, :license_list_command, :make_licensing_optional

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

      def license_add_command
        @license_add_command ||= "license add"
      end

      def license_list_command
        @license_list_command ||= "license list"
      end

      def make_licensing_optional
        @make_licensing_optional ||= false
      end

      def require_license_for
        return unless block_given?

        @require_license_mutex ||= Mutex.new

        @require_license_mutex.synchronize do
          # Store the original value by calling the method, not accessing the instance variable
          original_value = make_licensing_optional

          begin
            # Temporarily set licensing as required (not optional)
            @make_licensing_optional = false
            # Enforce the license requirement by fetching and persisting the license keys
            ChefLicensing.fetch_and_persist
            yield
          ensure
            # Always restore the original value, even if an exception occurs
            @make_licensing_optional = original_value
          end
        end
      end
    end
  end
end
