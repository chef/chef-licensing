require "logger"
require_relative "config_fetcher/arg_fetcher"
require_relative "config_fetcher/env_fetcher"

module ChefLicensing
  class ChefLicensingLogger < ::Logger

    # TODO: Verify if we need to change the class name
    # TODO: Mature the logger class after discussing with the team

    def initialize
      super(log_output)
      self.level = log_level
    end

    private

    def log_level
      arg_fetcher = ChefLicensing::ArgFetcher::String.new("log-level")
      env_fetcher = ChefLicensing::EnvFetcher::String.new("CHEF_LOG_LEVEL")

      arg_fetcher.value || env_fetcher.value || "info"
    end

    def log_output
      arg_fetcher = ChefLicensing::ArgFetcher::String.new("log-output")
      env_fetcher = ChefLicensing::EnvFetcher::String.new("CHEF_LOG_OUTPUT")

      # TODO: Decide if we need to support STDOUT or STDERR as default value
      arg_fetcher.value || env_fetcher.value || STDERR
    end
  end
end
