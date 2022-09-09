module ChefLicensing
  class LicenseKeyFetcher
    class Base
      # TODO: get the correct regex, it's not really 8 digits
      LICENSE_KEY_REGEX = "(\d{8})".freeze
      LICENSE_KEY_PATTERN_DESC = "eight digits".freeze
    end
  end
end
