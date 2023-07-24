require_relative "base"

module ChefLicensing
  module LicenseFile
    class V3 < Base
      LICENSE_FILE_FORMAT_VERSION = "3.0.0".freeze
      EXPECTED_STRUCTURE = EXPECTED_STRUCTURE.merge({
        file_format_version: V3::LICENSE_FILE_FORMAT_VERSION,
      }).freeze
    end
  end
end
