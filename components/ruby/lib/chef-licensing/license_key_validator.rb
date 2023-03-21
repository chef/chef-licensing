require_relative "restful_client/v1"
require_relative "exceptions/invalid_license"

module ChefLicensing
  class LicenseKeyValidator
    attr_reader :license

    class << self
      def validate!(license)
        new(license).validate!
      end
    end

    def initialize(license, restful_client: ChefLicensing::RestfulClient::V1)
      @license = license || raise(ArgumentError, "Missing Params: `license`")
      @restful_client = restful_client.new
    end

    def validate!
      response = @restful_client.validate(license)
      response.data || raise(ChefLicensing::InvalidLicense, response.message)
    end
  end
end