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
    attr_accessor :commercial_license_expired

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
        unless licenses_require_renewal?(@license_keys)
          return @license_keys
        end
      end

      # Lowest priority is to interactively prompt if we have a TTY
      if config[:output].isatty
        logger.debug "License Key fetcher - detected TTY, prompting..."
        new_keys = prompt_fetcher.fetch

        # Scenario 1: When a user is prompted for license expiry beforehand expiration and license is not yet renewed
        # Scenario 2: When a user is prompted for license expired and it is a commercial license
        if new_keys.empty?
          if (config[:start_interaction] == :prompt_license_about_to_expire) || (config[:start_interaction] == :prompt_license_expired && commercial_license_expired)
            return @license_keys
          end
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

    def licenses_require_renewal?(license_keys)
      license_expiry_hash = {}
      license_keys.each do |license_key|

        # TODO API error handling to be done after API is available

        # Fetching expiry info for each license
        if ChefLicensing::LicenseKeyValidator.license_expired?(license_key)
          license_expiry_hash[license_key] = "expired"
        elsif ChefLicensing::LicenseKeyValidator.license_about_to_expire?(license_key)
          license_expiry_hash[license_key] = "about_to_expire"
        end

        # Setting commercial license expiry flag incase expired
        if license_expiry_hash[license_key] == "expired" && (ChefLicensing::LicenseKeyValidator.license_type(license_key) == "commercial")
          self.commercial_license_expired = true
        end
      end

      # Renewal check condition
      if license_expiry_hash.values.all?("expired")
        config[:start_interaction] = :prompt_license_expired
        prompt_fetcher.config = config
        return true
      elsif license_expiry_hash.values.any?("about_to_expire")
        config[:start_interaction] = :prompt_license_about_to_expire
        prompt_fetcher.config = config
        return true
      end

      false
    end
  end
end
