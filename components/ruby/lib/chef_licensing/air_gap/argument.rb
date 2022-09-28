module ChefLicensing
  class AirGap
    class Argument

      attr_reader :argv, :status

      def initialize(argv)
        @argv = argv
      end

      def verify_argv
        return @status if @status # memoize

        @status = argv.include?("--airgap")
      rescue => exception
        raise AirGapException, "Unable to verify air gap argument.\n#{exception.message}"
      end
    end
  end
end
