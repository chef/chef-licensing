# TODO: Delete this file. Not required after config implementation.

module ChefLicensing
  class AirGapDetection
    class Environment

      # If status is true, airgap mode is on - we are isolated.
      attr_reader :env, :status

      def initialize(env)
        @env = env
      end

      def detected?
        return @status unless @status.nil? # memoize

        @status = @env.key?("CHEF_AIR_GAP")
      end
    end
  end
end
