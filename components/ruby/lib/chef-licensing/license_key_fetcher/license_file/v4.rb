require_relative "base"
require_relative "../../config"

module ChefLicensing
  module LicenseFile
    class V4 < Base
      LICENSE_FILE_FORMAT_VERSION = "4.0.0".freeze

      EXPECTED_STRUCTURE = EXPECTED_STRUCTURE.merge({
        file_format_version: V4::LICENSE_FILE_FORMAT_VERSION,
        license_server_url: String,
      }).freeze

      # @param [Hash] contents: The contents of the license file
      # @param [Integer] version: The version of the license file
      # @return [Hash] The contents of the license file after migration
      def self.migrate_structure(contents, version)
        # Backwards compatibility for version 3 license files
        if version == 3
          contents[:license_server_url] = ChefLicensing::Config.license_server_url || ""
          contents[:file_format_version] = V4::LICENSE_FILE_FORMAT_VERSION
        end
        contents
      end
    end
  end
end
