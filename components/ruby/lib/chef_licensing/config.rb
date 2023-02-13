require "singleton" unless defined?(Singleton)
require "logger"
require_relative "config_fetcher/arg_fetcher"
require_relative "config_fetcher/env_fetcher"

# TODO: Find a better way to do ping check
require_relative "air_gap_detection/ping"

module ChefLicensing
  class Config
    class << self
      attr_writer :license_server_url, :license_server_api_key, :air_gap_status, :chef_product_name, :chef_entitlement_id, :logger, :output

      def license_server_url
        @license_server_url ||= ChefLicensing::ArgFetcher.fetch_value("--chef-license-server", :string) || ChefLicensing::EnvFetcher.fetch_value("CHEF_LICENSE_SERVER", :string)
      end

      def license_server_api_key
        @license_server_api_key ||= ChefLicensing::ArgFetcher.fetch_value("--chef-license-server-api-key", :string) || ChefLicensing::EnvFetcher.fetch_value("CHEF_LICENSE_SERVER_API_KEY", :string)
      end

      def air_gap_detected?
        return @air_gap_status unless @air_gap_status.nil?

        # TODO: Find a better way to do ping check
        # TODO: Check if the license_server_url is nil
        ping_check = AirGapDetection::Ping.new(license_server_url)
        @air_gap_status = ChefLicensing::ArgFetcher.fetch_value("--airgap", :boolean) ||
          ChefLicensing::EnvFetcher.fetch_value("CHEF_AIR_GAP", :boolean) ||
          ping_check.detected?
      end

      def chef_entitlement_id
        @chef_entitlement_id ||= ChefLicensing::ArgFetcher.fetch_value("--chef-entitlement-id", :string) || ChefLicensing::EnvFetcher.fetch_value("CHEF_ENTITLEMENT_ID", :string)
      end

      def chef_product_name
        @chef_product_name ||= ChefLicensing::ArgFetcher.fetch_value("--chef-product-name", :string) || ChefLicensing::EnvFetcher.fetch_value("CHEF_PRODUCT_NAME", :string)
      end

      def logger
        return @logger if @logger

        @logger = Logger.new(STDERR)
        @logger.level = Logger::INFO
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
