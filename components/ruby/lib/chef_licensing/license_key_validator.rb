require_relative "restful_client/v1"
require_relative "exceptions/invalid_license"

module ChefLicensing
  class LicenseKeyValidator
    attr_reader :license

    class << self
      def validate!(license, cl_config: nil)
        new(license, cl_config: cl_config).validate!
      end
    end

    def initialize(license, restful_client: ChefLicensing::RestfulClient::V1, cl_config: nil)
      @license = license || raise(ArgumentError, "Missing Params: `license`")
      @restful_client = restful_client.new(cl_config: cl_config)
    end

    def validate!
      response = restful_client.validate(license)
      response.data || raise(ChefLicensing::InvalidLicense, response.message)
    end

    private

    attr_reader :restful_client
  end
end