require "chef-config/path_helper"
require "chef-config/windows"
require "logger"

require_relative "license_key_fetcher/argument"
require_relative "license_key_fetcher/environment"
require_relative "license_key_fetcher/file"
require_relative "license_key_fetcher/prompt"

# LicenseKeyFetcher allows us to inspect obtain the license Key from the user in a variety of ways.
module ChefLicensing
  class LicenseKeyFetcher
    class LicenseKeyNotFetchedError < Exception
    end

    attr_reader :config, :license_key, :arg_fetcher, :env_fetcher, :file_fetcher, :prompt_fetcher, :logger
    def initialize(opts = {})
      @config = opts
      @logger = opts[:logger] || Logger.new(opts.key?(:output) ? opts[:output] : STDERR)
      @config[:output] ||= STDOUT
      config[:logger] = logger
      config[:dir] = opts[:dir]

      # This is the whole point - to obtain the license key.
      @license_key = nil

      # The various things that have a say in fetching the license Key.
      @arg_fetcher = LicenseKeyFetcher::Argument.new(ARGV)
      @env_fetcher = LicenseKeyFetcher::Environment.new(ENV)
      @file_fetcher = LicenseKeyFetcher::File.new(config)
      @prompt_fetcher = LicenseKeyFetcher::Prompt.new(config)
    end

    #
    # Methods for obtaining consent from the user.
    #
    def fetch_and_persist(product, version)

      # TODO: handle non-persistent cases

      # If a fetch is made by CLI arg, persist and return
      logger.debug "Telemetry license Key fetcher examining CLI arg checks"
      if @license_key = @arg_fetcher.fetch
        file_fetcher.persist(license_key, product, version)
        return license_key
      end

      # If a fetch is made by ENV, persist and return
      logger.debug "Telemetry license Key fetcher examining ENV checks"
      if @license_key = @env_fetcher.fetch
        file_fetcher.persist(license_key, product, version)
        return license_key
      end

      # If it has previously been fetched and persisted, read from disk and set runtime decision
      logger.debug "Telemetry license Key fetcher examining file checks"
      if file_fetcher.persisted?
        return @license_key = file_fetcher.fetch
      end

      # Lowest priority is to interactively prompt if we have a TTY
      if config[:output].isatty
        logger.debug "Telemetry license Key fetcher - detected TTY, prompting..."
        if @license_key = prompt_fetcher.fetch
          file_fetcher.persist(license_key, product, version)
          return license_key
        end
      end

      # Otherwise nothing was able to fetch a license. Throw an exception.
      logger.debug "Telemetry license Key fetcher - no license Key able to be fetched."
      raise LicenseKeyNotFetchedError.new("Unable to obtain a License Key.")

    end

    # Assumes fetch_and_persist has been called and succeeded
    def fetch(_product, _version)
      @arg_fetcher.fetch || @env_fetcher.fetch || @file_fetcher.fetch
    end

    def self.fetch_and_persist(product, version, opts)
      new(opts).fetch_and_persist(product, version)
    end

    def self.fetch(product, version, opts)
      new(opts).fetch(product, version)
    end

  end
end
