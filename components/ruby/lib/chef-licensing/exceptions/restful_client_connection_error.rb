require_relative "error"

module ChefLicensing
  class RestfulClientConnectionError < Error
    def message
      super || "Restful Client Connection Error"
    end
  end
end
