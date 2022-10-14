require_relative "exception"

module ChefLicensing
  class AirGapDetection
    class Environment

      # If status is true, airgap mode is on - we are isolated.
      attr_reader :env, :status

      def initialize(env)
        @env = env
      end

      def detected?
        return @status if @status # memoize

        @status = @env["CHEF_AIR_GAP"] == "enabled"
      rescue => exception
        raise ChefLicensing::AirGapDetectionException, "Unable to verify air gap environment variable.\n#{exception.message}"
      end
    end
  end
end
