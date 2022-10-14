require_relative "exception"

module ChefLicensing
  class AirGap
    class Argument

      # If status is true, airgap mode is on - we are isolated.
      attr_reader :argv, :status

      def initialize(argv)
        @argv = argv
      end

      def enabled?
        return @status if @status # memoize

        @status = argv.include?("--airgap")
      rescue => exception
        raise ChefLicensing::AirGapException, "Unable to verify air gap argument.\n#{exception.message}"
      end
    end
  end
end
