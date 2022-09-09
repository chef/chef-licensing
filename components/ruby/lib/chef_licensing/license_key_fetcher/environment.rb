require_relative "base"

module ChefLicensing
  class LicenseKeyFetcher

    # Represents fetching a license ID by environment variables.
    class Environment < Base

      attr_reader :env

      def initialize(env)
        @env = env
      end

      def fetch
        if env["CHEF_LICENSE_KEY"]
          if (match = env["CHEF_LICENSE_KEY"].match(/^#{LICENSE_KEY_REGEX}$/))
            match[1]
          else
            raise LicenseKeyNotFetchedError.new("Malformed License Key passed in ENV variable CHEF_LICENSE_KEY - should be #{LICENSE_KEY_PATTERN_DESC}")
          end
        end
        nil
      end
    end
  end
end
