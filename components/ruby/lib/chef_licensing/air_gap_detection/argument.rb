module ChefLicensing
  class AirGapDetection
    class Argument

      # If status is true, airgap mode is on - we are isolated.
      attr_reader :argv, :status

      def initialize(argv)
        @argv = argv
      end

      def detected?
        return @status unless @status.nil? # memoize

        @status = argv.include?("--airgap")
      end
    end
  end
end
