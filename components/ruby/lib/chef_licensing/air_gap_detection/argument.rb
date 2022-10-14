require_relative "exception"

module ChefLicensing
  class AirGapDetection
    class Argument

      # If status is true, airgap mode is on - we are isolated.
      attr_reader :argv, :status

      def initialize(argv)
        @argv = argv
      end

      def detected?
        return @status if @status # memoize

        @status = argv.include?("--airgap")
      rescue => exception
        raise ChefLicensing::AirGapDetectionException, "Unable to verify air gap argument.\n#{exception.message}"
      end
    end
  end
end
