require "chef-config/path_helper"
require "chef-config/windows"

require_relative "config"
require_relative "config_fetcher/arg_fetcher"
require_relative "config_fetcher/env_fetcher"
require_relative "license_key_fetcher/base"
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
      @logger = ChefLicensing::Config.logger
      @config[:output] = ChefLicensing::Config.output
      config[:logger] = logger
      config[:dir] = opts[:dir]

      # This is the whole point - to obtain the license keys.
      @license_keys = []

      argv = opts[:argv] || ARGV
      env = opts[:env] || ENV

      # The various things that have a say in fetching the license Key.
      @arg_fetcher = ChefLicensing::ArgFetcher.new(argv)
      @env_fetcher = ChefLicensing::EnvFetcher.new(env)
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

      new_keys = fetch_license_key_from_arg
      unless new_keys.empty?
        @license_keys.concat(new_keys)
        file_fetcher.validate_and_persist(new_keys.first)
        return new_keys
      end

      # If a fetch is made by ENV, persist and return
      logger.debug "License Key fetcher examining ENV checks"
      new_keys = fetch_license_key_from_env
      unless new_keys.empty?
        @license_keys.concat(new_keys)
        file_fetcher.validate_and_persist(new_keys.first)
        return new_keys
      end

      # If it has previously been fetched and persisted, read from disk and set runtime decision
      logger.debug "License Key fetcher examining file checks"
      if file_fetcher.persisted?
        return @license_keys = file_fetcher.fetch
      end

      # Lowest priority is to interactively prompt if we have a TTY
      if config[:output].isatty
        logger.debug "License Key fetcher - detected TTY, prompting..."
        new_keys = prompt_fetcher.fetch
        unless new_keys.empty?
          @license_keys.concat(new_keys)
          new_keys.each { |key| file_fetcher.persist(key) }
          return license_keys
        end
      end

      # Otherwise nothing was able to fetch a license. Throw an exception.
      logger.debug "License Key fetcher - no license Key able to be fetched."
      raise LicenseKeyNotFetchedError.new("Unable to obtain a License Key.")
    end

    # Note: Fetching from arg and env as well, to be able to fetch license when disk is non-writable
    def fetch
      (fetch_license_key_from_arg << fetch_license_key_from_env << @file_fetcher.fetch).flatten.uniq
    end

    def self.fetch_and_persist(opts = {})
      new(opts).fetch_and_persist
    end

    def self.fetch(opts = {})
      new(opts).fetch
    end

    private

    def fetch_license_key_from_arg
      new_key = @arg_fetcher.fetch_value("--chef-license-key")
      validate_license_key_format(new_key)
    end

    def fetch_license_key_from_env
      new_key = @env_fetcher.fetch_value("CHEF_LICENSE_KEY")
      validate_license_key_format(new_key)
    end

    def validate_license_key_format(license_key)
      return [] if license_key.nil?

      unless license_key.match(/^#{ ChefLicensing::LicenseKeyFetcher::Base::LICENSE_KEY_REGEX}$/)
        raise LicenseKeyNotFetchedError.new("Malformed License Key passed on command line - should be #{ChefLicensing::LicenseKeyFetcher::Base::LICENSE_KEY_PATTERN_DESC}")
      end

      [license_key]
    end

  end
end
