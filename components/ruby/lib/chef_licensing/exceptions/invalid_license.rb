require_relative "error"

module ChefLicensing
  class InvalidLicense < Error
    def message
      "Invalid License"
    end
  end
end

