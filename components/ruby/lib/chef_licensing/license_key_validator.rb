module ChefLicensing
  class LicenseKeyValidator
    attr_reader :license

    def initialize(license, restful_client: ChefLicensing::RestfulClient::V1)
      @license = license.presence || raise(ArgumentError, 'Missing Params: `license`')
      @restful_client = restful_client.new
    end

    def validate!
      response = restful_client.validate(license)
      # response outputs
      #raise ChefLicensing::InvalidLicense
    end

    private

    attr_reader :restful_client
  end
end