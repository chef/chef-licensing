module ChefLicensing
  class AirGap
    class Environment

      attr_reader :env

      def initialize(env)
        @env = env
      end

      def verify_env
        raise AirGapException, "AIR_GAP environment variable is enabled." if @env["AIR_GAP"] == "enabled"
      end
    end
  end
end