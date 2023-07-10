require_relative "error"

module ChefLicensing
  class InvalidFileFormatVersion < Error
    def message
      super || "Invalid File Format Version"
    end
  end
end

