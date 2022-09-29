require_relative "error"

module ChefLicensing
  class InvalidLicense < Error
    def message
      super || "Invalid License"
    end
  end
end

