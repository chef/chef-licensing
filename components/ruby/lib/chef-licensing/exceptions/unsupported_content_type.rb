require_relative "error"

module ChefLicensing
  class UnsupportedContentType < Error
    def message
      super || "Unsupported content type"
    end
  end
end
