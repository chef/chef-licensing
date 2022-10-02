require_relative "exception"

module ChefLicensing
  class AirGap
    class Environment

      attr_reader :env, :status

      def initialize(env)
        @env = env
      end

      def verify_env
        return @status if @status # memoize

        @status = @env["AIR_GAP"] == "enabled"
      rescue => exception
        raise ChefLicensing::AirGapException, "Unable to verify air gap environment variable.\n#{exception.message}"
      end
    end
  end
end
