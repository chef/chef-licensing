require_relative "error"

module ChefLicensing
  class InvalidEntitlement < Error
    def message
      super || "Invalid Entitlement"
    end
  end
end
