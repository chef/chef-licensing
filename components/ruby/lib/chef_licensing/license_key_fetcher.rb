require "chef-config/path_helper"
require "chef-config/windows"
require "logger"

require_relative "config"
require_relative "license_key_validator"
require_relative "license_key_fetcher/argument"
require_relative "license_key_fetcher/environment"
require_relative "license_key_fetcher/file"
require_relative "license_key_fetcher/prompt"

# LicenseKeyFetcher allows us to inspect obtain the license Key from the user in a variety of ways.
module ChefLicensing
  class LicenseKeyFetcher
    class LicenseKeyNotFetchedError < RuntimeError
    end

    attr_reader :config, :license_keys, :arg_fetcher, :env_fetcher, :file_fetcher, :prompt_fetcher, :logger
    def initialize(opts = {})
      @config = opts
      @logger = opts[:logger] || Logger.new(opts.key?(:output) ? opts[:output] : STDERR)
      @config[:output] ||= STDOUT
      config[:logger] = logger
      config[:dir] = opts[:dir]

      # This is the whole point - to obtain the license keys.
      @license_keys = []

      # The various things that have a say in fetching the license Key.
      @arg_fetcher = LicenseKeyFetcher::Argument.new(ARGV)
      @env_fetcher = LicenseKeyFetcher::Environment.new(ENV)
      @file_fetcher = LicenseKeyFetcher::File.new(config)
      @prompt_fetcher = LicenseKeyFetcher::Prompt.new(config)
    end

    #
    # Methods for obtaining consent from the user.
    #
    def fetch_and_persist
      # TODO: handle non-persistent cases
      # If a fetch is made by CLI arg, persist and return
      logger.debug "License Key fetcher examining CLI arg checks"

      new_keys = arg_fetcher.fetch
      unless new_keys.empty?
        @license_keys.concat(new_keys)
        file_fetcher.persist(new_keys.first)
      end

      # If a fetch is made by ENV, persist and return
      logger.debug "License Key fetcher examining ENV checks"
      new_keys = env_fetcher.fetch
      unless new_keys.empty?
        @license_keys.concat(new_keys)
        file_fetcher.persist(new_keys.first)
      end

      # If it has previously been fetched and persisted, read from disk and set runtime decision
      logger.debug "License Key fetcher examining file checks"
      if file_fetcher.persisted?
        @license_keys = file_fetcher.fetch
      end

      # licenses expiration check
      unless @license_keys.empty?
        if ChefLicensing::LicenseKeyValidator.licenses_expired?(@license_keys)
          config[:start_interaction] = :prompt_license_expired
          prompt_fetcher.config = config
        elsif ChefLicensing::LicenseKeyValidator.licenses_about_to_expire?(@license_keys)
          config[:start_interaction] = :prompt_license_about_to_expire
          prompt_fetcher.config = config
        else
          return @license_keys
        end
      end

      # Lowest priority is to interactively prompt if we have a TTY
      if config[:output].isatty
        logger.debug "License Key fetcher - detected TTY, prompting..."
        new_keys = prompt_fetcher.fetch

        # Scenario: When a user is prompted for license expiry beforehand expiration and license is not yet renewed
        if new_keys.empty? && (config[:start_interaction] == :prompt_license_about_to_expire)
          return @license_keys
        elsif !new_keys.empty?
          @license_keys.concat(new_keys)
          new_keys.each { |key| file_fetcher.persist(key) }
          return license_keys
        end
      end

      # Otherwise nothing was able to fetch a license. Throw an exception.
      logger.debug "License Key fetcher - no license Key able to be fetched."
      raise LicenseKeyNotFetchedError.new("Unable to obtain a License Key.")
    end

    # Assumes fetch_and_persist has been called and succeeded
    def fetch
      @file_fetcher.fetch
    end

    def self.fetch_and_persist(opts = {})
      new(opts).fetch_and_persist
    end

    def self.fetch(opts = {})
      new(opts).fetch
    end
  end
end
