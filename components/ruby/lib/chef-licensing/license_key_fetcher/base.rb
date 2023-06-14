require_relative "../exceptions/invalid_license"
module ChefLicensing
  class LicenseKeyFetcher
    class Base
      # @example LICENSE UUID: tmns-58555821-925e-4a27-8fdc-e79dae5a425b-9763
      # @example SERIAL NUMBER: A8BCD1XS2B4F6FYBWG8TE0N490
      # @example COMMERCIAL KEY: e0b8f309-6abd-4668-909b-ef2d5fc043a1
      # 4[license type]-(8-4-4-4-12)[GUID]-4[timestamp]
      LICENSE_KEY_REGEX = "([a-z]{4}-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}-[0-9]{1,4})".freeze
      LICENSE_KEY_PATTERN_DESC = "Hexadecimal".freeze
      # Serial number is a 26 character alphanumeric string
      SERIAL_KEY_REGEX = "([A-Z0-9]{26})".freeze
      SERIAL_KEY_PATTERN_DESC = "26 character alphanumeric string".freeze
      COMMERCIAL_KEY_REGEX = "([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})".freeze
      QUIT_KEY_REGEX = "(q|Q)".freeze

      def self.verify_and_extract_license(license_key)
        if license_key && (match = license_key.match(/^#{LICENSE_KEY_REGEX}$/) || license_key.match(/^#{SERIAL_KEY_REGEX}$/) || license_key.match(/^#{COMMERCIAL_KEY_REGEX}$/))
          match[1]
        else
          raise InvalidLicenseKeyFormat, "Malformed License Key passed on command line - should be #{LICENSE_KEY_PATTERN_DESC} or #{SERIAL_KEY_PATTERN_DESC}"
        end
      end

      class InvalidLicenseKeyFormat < InvalidLicense; end
    end
  end
end
