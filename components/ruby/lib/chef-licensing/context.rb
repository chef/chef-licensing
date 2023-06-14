# Context defines the interface for state management in chef-licensing
# Different states : local or global

# Licensing service detection
require_relative "licensing_service/local"

module ChefLicensing
  class Context

    attr_accessor :state
    attr_reader :logger, :options

    class << self
      attr_writer :current_context

      def local_licensing_service?
        ChefLicensing::Config.is_local_license_service ||= LicensingService::Local.detected?
      end

      # Implement methods on current context
      # Current context changes the state determined using LicensingService module

      # Return license keys from current context
      def license_keys(options = {})
        current_context(options).license_keys
      end

      private

      def current_context(options)
        return @current_context if @current_context

        @current_context = context_based_on_state(options)
      end

      def context_based_on_state(options)
        if local_licensing_service?
          new(Local.new, options)
        else
          new(Global.new, options)
        end
      end

    end

    # @param [State] state
    def initialize(state, options = {})
      @options = options
      @logger = ChefLicensing::Config.logger
      transition_to(state)
    end

    # The Context allows changing the State object
    def transition_to(state)
      logger.debug "Chef Licensing Context: Transition to #{state.class}"
      @state = state
      @state.context = self
      @state.options = options
    end

    # The Context delegates part of its behavior to the current State object.
    def license_keys
      @state.license_keys
    end

    class State
      attr_accessor :context, :options

      # @abstract
      def license_keys
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
      end
    end

    # Implement various behaviors, associated with a state of the Context.

    class Local < State
      def license_keys
        @license_keys ||= ChefLicensing::Api::ListLicenses.info || []
      end
    end

    class Global < State
      def license_keys
        @license_keys ||= fetch_license_keys_from_file || []
      end

      def fetch_license_keys_from_file
        file_fetcher = LicenseKeyFetcher::File.new(options)
        if file_fetcher.persisted?
          # This could be useful if the file was writable in past but is not writable in current scenario and new keys are not persisted in the file
          file_fetcher.fetch
        end
      end
    end

  end
end
