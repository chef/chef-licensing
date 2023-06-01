# Context defines the interface for state management in chef-licensing
# Different states : local or global

# Licensing service detection
require_relative "licensing_service/local"

module ChefLicensing
  class Context

    attr_accessor :state
    attr_reader :logger

    class << self
      def local_licensing_service?
        ChefLicensing::Config.is_local_license_service ||= LicensingService::Local.detected?
      end

      # Implement methods on current context
      # Current context changes the state determined using LicensingService module

      # Return license keys from current context
      def license_keys
        current_context.license_keys
      end

      private

      def current_context
        @current_context ||= local_licensing_service? ? new(Local.new) : new(Global.new)
      end
    end

    # @param [State] state
    def initialize(state)
      @logger = ChefLicensing::Config.logger
      transition_to(state)
    end

    # The Context allows changing the State object
    def transition_to(state)
      logger.debug "Chef Licensing Context: Transition to #{state.class}"
      @state = state
      @state.context = self
    end

    # The Context delegates part of its behavior to the current State object.
    def license_keys
      @state.license_keys
    end

    class State
      attr_accessor :context

      # @abstract
      def license_keys
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
      end
    end

    # Implement various behaviors, associated with a state of the Context.

    class Local < State
      def license_keys
        @license_keys ||= ChefLicensing::Api::ListLicenses.info
      end
    end

    class Global < State
      def license_keys
        # TODO - Return keys from file
      end
    end

  end
end
