require_relative "base"

module ChefLicensing
  class LicenseKeyFetcher

    # Represents getting a license ID by CLI argument
    class Argument < Base

      attr_reader :argv

      def initialize(args = ARGV)
        @argv = args
      end

      def fetch
        # TODO: this only handles explicit equals
        # TODO: WhyTF are we hand-rolling an option parser
        arg = argv.detect { |a| a.start_with? "--chef-license-key=" }
        return nil unless arg
        match = arg.match(/--chef-license-key=#{LICENSE_KEY_REGEX}/)
        unless match
          raise LicenseKeyNotFetchedError.new("Malformed License Key passed on command line - should be #{LICENSE_KEY_PATTERN_DESC}")
        end
        return match[1]
      end
    end
  end
end
