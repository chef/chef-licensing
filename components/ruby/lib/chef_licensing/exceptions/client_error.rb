require_relative "error"

module ChefLicensing
  class ClientError < Error
    def message
      super || "License Client API failure"
    end
  end
end