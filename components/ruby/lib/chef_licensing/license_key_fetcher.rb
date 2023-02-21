require "chef-config/path_helper"
require "chef-config/windows"

require_relative "config"
require_relative "license_key_fetcher/argument"
require_relative "license_key_fetcher/environment"
require_relative "license_key_fetcher/file"
require_relative "license_key_fetcher/prompt"
require "chef_licensing"

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
      @arg_fetcher = LicenseKeyFetcher::Argument.new(argv)
      @env_fetcher = LicenseKeyFetcher::Environment.new(env)
      @file_fetcher = LicenseKeyFetcher::File.new(config)
      @prompt_fetcher = LicenseKeyFetcher::Prompt.new(config)
      @client = nil
    end

    #
    # Methods for obtaining consent from the user.
    #
    def fetch_and_persist
      # TODO: handle non-persistent cases
      # If a fetch is made by CLI arg, persist and return
      logger.debug "License Key fetcher examining CLI arg checks"
      fetch_from_arguments

      # If a fetch is made by ENV, persist and return
      logger.debug "License Key fetcher examining ENV checks"
      fetch_from_env

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
        logger.debug "License Key fetcher - detected TTY, prompting..."
        new_keys = prompt_fetcher.fetch

        # Scenario: When a user is prompted for license expiry beforehand expiration and license is not yet renewed
        if new_keys.empty?
          if (config[:start_interaction] == :prompt_license_about_to_expire) || ((config[:start_interaction] == :prompt_license_expired) && have_grace?)
            return @license_keys
          end
        elsif !new_keys.empty?
          @license_keys.concat(new_keys)
          new_keys.each { |key| file_fetcher.persist(key) }
          return license_keys
        end
      else
        if config[:start_interaction] == :prompt_license_about_to_expire
          logger.warn "Your #{client.license_type} license is going to expire tomorrow."
          return false
        elsif config[:start_interaction] == :prompt_license_expired
          if have_grace?
            logger.error "Your #{client.license_type} license has been expired."
            return false
          else
            logger.error "Your #{client.license_type} license has been expired."
            raise LicenseKeyNotFetchedError.new("License has been expired.")
          end
        end
      end

      # Otherwise nothing was able to fetch a license. Throw an exception.
      logger.debug "License Key fetcher - no license Key able to be fetched."
      raise LicenseKeyNotFetchedError.new("Unable to obtain a License Key.")
    end

    # Note: Fetching from arg and env as well, to be able to fetch license when disk is non-writable
    def fetch
      (@arg_fetcher.fetch << @env_fetcher.fetch << @file_fetcher.fetch).flatten.uniq
    end

    def self.fetch_and_persist(opts = {})
      new(opts).fetch_and_persist
    end

    def self.fetch(opts = {})
      new(opts).fetch
    end

    private

    attr_accessor :client

    def fetch_from_arguments
      new_keys = arg_fetcher.fetch
      unless new_keys.empty?
        @license_keys.concat(new_keys)
        file_fetcher.validate_and_persist(new_keys.first)
      end
      @license_keys
    end

    def fetch_from_env
      new_keys = env_fetcher.fetch
      unless new_keys.empty?
        @license_keys.concat(new_keys)
        file_fetcher.validate_and_persist(new_keys.first)
      end
      @license_keys
    end

    def fetch_from_file
      if file_fetcher.persisted?
        # This could be useful if the file was writable in past but is not writable in current scenario and new keys are not persisted in the file
        file_keys = file_fetcher.fetch
        @license_keys.concat(file_keys).uniq # uniq is required in case file was a writable and to avoid repeated values.
      end
      @license_keys
    end

    def licenses_active?
      self.client = ChefLicensing.client(license_keys: @license_keys)
      if expired? || have_grace?
        config[:start_interaction] = :prompt_license_expired
        prompt_fetcher.config = config
        false
      elsif about_to_expire?
        config[:start_interaction] = :prompt_license_about_to_expire
        prompt_fetcher.config = config
        false
      else
        true
      end
    end

    def have_grace?
      client.status.eql?("Grace")
    end

    def expired?
      client.status.eql?("Expired")
    end

    def about_to_expire?
      require "Date" unless defined?(Date)
      client.status.eql?("Active") && client.expiration_status.eql?("Expired") && (Date.parse(client.expiration_date) - Date.today).to_i.eql?(1)
    end
  end
end