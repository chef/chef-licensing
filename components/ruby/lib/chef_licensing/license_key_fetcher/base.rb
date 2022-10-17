module ChefLicensing
  class LicenseKeyFetcher
    class Base
      # @example LICENSE UUID: tmns-58555821-925e-4a27-8fdc-e79dae5a425b-9763
      # 4[license type]-(8-4-4-4-12)[GUID]-4[timestamp]
      LICENSE_KEY_REGEX = "([a-z]{4}-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}-[0-9]{1,4})".freeze
      LICENSE_KEY_PATTERN_DESC = "Hexadecimal".freeze
      QUIT_KEY_REGEX = "(q|Q)".freeze
    end
  end
end
