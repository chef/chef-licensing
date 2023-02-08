require "singleton" unless defined?(Singleton)
require "logger"
require_relative "config_fetcher/arg_fetcher"
require_relative "config_fetcher/env_fetcher"

# TODO: Find a better way to do ping check
require_relative "air_gap_detection/ping"

module ChefLicensing
  class Config
    include Singleton

    attr_reader :license_server_url, :license_server_api_key, :logger, :air_gap_status, :arg_fetcher, :env_fetcher, :chef_product_name, :chef_entitlement_id, :output

    def initialize(opts = {})
      @arg_fetcher = ChefLicensing::ArgFetcher.new(opts[:cli_args] || ARGV)
      @env_fetcher = ChefLicensing::EnvFetcher.new(opts[:env_vars] || ENV)
      @output = opts[:output] || set_output_stream
      @logger = opts[:logger] || set_default_logger
      @license_server_api_key = set_license_server_api_key
      @license_server_url = set_license_server_url
      @chef_product_name = set_chef_product_name
      @chef_entitlement_id = set_chef_entitlement_id
    end

    def self.instance(opts = {})
      return @instance if @instance

      @instance = new(opts)
    end

    def self.reset!
      @instance = nil
    end

    def air_gap_detected?
      return @air_gap_status unless @air_gap_status.nil?

      # TODO: Find a better way to do ping check
      ping_check = AirGapDetection::Ping.new(license_server_url, @logger)
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

    def set_chef_product_name
      @arg_fetcher.fetch_value("--chef-product-name", :string) || @env_fetcher.fetch_value("CHEF_PRODUCT_NAME", :string)
    end

    def set_chef_entitlement_id
      @arg_fetcher.fetch_value("--chef-entitlement-id", :string) || @env_fetcher.fetch_value("CHEF_ENTITLEMENT_ID", :string)
    end

    def set_default_logger
      logger = Logger.new(@output)
      logger_level = @arg_fetcher.fetch_value("--chef-license-logger-level", :string) || @env_fetcher.fetch_value("CHEF_LICENSE_LOGGER_LEVEL", :string)
      logger.level = logger_level ? Logger.const_get(logger_level.upcase) : Logger::INFO
      logger
    end

    def set_output_stream
      # TODO: Improve the experience maybe?
      # TODO: Improve the flag/arugment name

      # Check the flag first if user wants to write to a file or to stdout
      stealth_check = @arg_fetcher.fetch_value("--chef-license-stealth-mode", :boolean) || @env_fetcher.fetch_value("CHEF_LICENSE_STEALTH_MODE", :boolean)

      return $stdout unless stealth_check

      # If user wants to write to a file, check if the file path is provided
      file_path = @arg_fetcher.fetch_value("--chef-license-output-file", :string) || @env_fetcher.fetch_value("CHEF_LICENSE_OUTPUT_FILE", :string)
      file_path ? File.open(file_path, "a") : StringIO.new
    end
  end
end
