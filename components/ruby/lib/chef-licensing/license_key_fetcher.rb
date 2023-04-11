require "chef-config/path_helper"
require "chef-config/windows"

require_relative "config"
require_relative "config_fetcher/arg_fetcher"
require_relative "config_fetcher/env_fetcher"
require_relative "license_key_fetcher/base"
require_relative "license_key_fetcher/file"
require_relative "license_key_fetcher/prompt"
require_relative "../chef-licensing"
require "tty-spinner"
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
      @license = nil
    end

    #
    # Methods for obtaining consent from the user.
    #
    def fetch_and_persist
      logger.debug "License Key fetcher examining CLI arg checks"
      new_keys = fetch_license_key_from_arg
      concat_validate_and_persist(new_keys)

      logger.debug "License Key fetcher examining ENV checks"
      new_keys = fetch_license_key_from_env
      concat_validate_and_persist(new_keys)

      # If it has previously been fetched and persisted, read from disk and set runtime decision
      logger.debug "License Key fetcher examining file checks"
      fetch_from_file

      @license_keys = @license_keys.uniq
      # licenses expiration check
      unless @license_keys.empty?
        return @license_keys if licenses_active?
      end

      # Lowest priority is to interactively prompt if we have a TTY
      if config[:output].isatty
        append_extra_info_to_tui_engine # will add extra dynamic values in tui flows
        logger.debug "License Key fetcher - detected TTY, prompting..."
        new_keys = prompt_fetcher.fetch

        unless new_keys.empty?
          @license_keys.concat(new_keys)
          new_keys.each { |key| file_fetcher.persist(key) }
          return license_keys
        end
      end

      # Scenario: When a user is prompted for license expiry and license is not yet renewed
      if new_keys.empty? && %i{prompt_license_about_to_expire prompt_license_expired}.include?(config[:start_interaction])
        # Not blocking any license type in case of expiry
        return @license_keys
      end

      # Otherwise nothing was able to fetch a license. Throw an exception.
      logger.debug "License Key fetcher - no license Key able to be fetched."
      raise LicenseKeyNotFetchedError.new("Unable to obtain a License Key.")
    end

    def add_license
      config[:start_interaction] = :add_license
      prompt_fetcher.config = config
      append_extra_info_to_tui_engine
      prompt_fetcher.fetch
    end

    def append_extra_info_to_tui_engine
      extra_info = {}
      extra_info[:chef_product_name] = ChefLicensing::Config.chef_product_name&.capitalize
      unless @license_keys.empty? && !license
        extra_info[:license_type] = license.license_type.capitalize
        extra_info[:number_of_days_in_expiration] = license.number_of_days_in_expiration
        extra_info[:license_expiration_date] = Date.parse(license.expiration_date).strftime("%a, %d %b %Y")
      end
      prompt_fetcher.append_info_to_tui_engine(extra_info) unless extra_info.empty?
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

    def self.add_license(opts = {})
      new(opts).add_license
    end

    private

    attr_accessor :license

    def fetch_from_file
      if file_fetcher.persisted?
        # This could be useful if the file was writable in past but is not writable in current scenario and new keys are not persisted in the file
        file_keys = file_fetcher.fetch
        @license_keys.concat(file_keys).uniq # uniq is required in case file was a writable and to avoid repeated values.
      end
      @license_keys
    end

    def licenses_active?
      spinner = TTY::Spinner.new(":spinner [Running] License validation in progress...", format: :dots, clear: true)
      spinner.auto_spin # Start the spinner
      # This call returns a license based on client logic
      self.license = ChefLicensing.client(license_keys: @license_keys)
      spinner.success # Stop the spinner
      if license.expired? || license.have_grace?
        config[:start_interaction] = :prompt_license_expired
        prompt_fetcher.config = config
        false
      elsif license.about_to_expire?
        config[:start_interaction] = :prompt_license_about_to_expire
        prompt_fetcher.config = config
        false
      else
        true
      end
    end

    def concat_validate_and_persist(new_keys)
      unless new_keys.empty?
        @license_keys.concat(new_keys)
        file_fetcher.validate_and_persist(new_keys.first)
      end
      @license_keys
    end

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

      license_key = ChefLicensing::LicenseKeyFetcher::Base.verify_and_extract_license(license_key)
      [license_key]
    end
  end
end