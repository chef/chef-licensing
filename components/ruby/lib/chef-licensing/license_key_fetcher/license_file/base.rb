module ChefLicensing
  module LicenseFile
    class Base
      EXPECTED_STRUCTURE = {
        file_format_version: "0.0.0",
        licenses: [
          {
            license_key: String,
            license_type: Symbol,
            update_time: String,
          },
        ],
      }.freeze

      # @param [Hash] data: The data to verify
      # @param [Hash] expected_structure: The structure to verify against
      # @return [Boolean] true if the data matches the expected structure, false otherwise
      # @note This method ignores extra keys in the data that are not in the expected structure
      def self.verify_structure(data, expected_structure = self::EXPECTED_STRUCTURE)
        return false unless data.is_a?(Hash)

        expected_structure.each do |key, value|
          return false unless data.key?(key)

          if value.is_a?(Hash)
            return false unless verify_structure(data[key], value)
          elsif value.is_a?(Array)
            return false unless data[key].is_a?(Array)

            data[key].each do |item|
              return false unless verify_structure(item, value[0])
            end
          elsif value.is_a?(Class)
            return false unless data[key].is_a?(value)
          else
            return false unless data[key] == value
          end
        end

        true
      end

      # @return [Hash] The primary structure of the license file, without nested structures
      def self.load_primary_structure
        expected_structure_dup = self::EXPECTED_STRUCTURE.dup
        expected_structure_dup[:licenses] = []
        expected_structure_dup
      end

      # @return [Hash] The complete structure of the license file, including nested structures
      def self.load_structure
        self::EXPECTED_STRUCTURE
      end

      # @param [Hash] contents: The contents of the license file
      # @param [Integer] version: The version of the license file
      # @return [Hash] The contents of the license file after migration
      def self.migrate_structure(contents, version)
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
      end
    end
  end
end
