module ChefLicensing
  class AirGap
    class Argument

      attr_reader :argv

      def initialize(argv)
        @argv = argv
      end

      def verify_argv
        raise AirGapException, "--airgap flag is enabled." if @argv.include?("--airgap")
      end
    end
  end
end
