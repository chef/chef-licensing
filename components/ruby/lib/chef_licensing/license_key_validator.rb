require_relative "restful_client/v1"
require_relative "exceptions/invalid_license"

module ChefLicensing
  class LicenseKeyValidator
    attr_reader :license, :license_keys

    class << self
      def validate!(license)
        new(license).validate!
      end

      def licenses_expired?(license_keys)
        new(license_keys).licenses_expired?
      end

      def licenses_about_to_expire?(license_keys)
        new(license_keys).licenses_about_to_expire?
      end
    end

    def initialize(license, restful_client: ChefLicensing::RestfulClient::V1)
      @license = license || raise(ArgumentError, "Missing Params: `license`")
      @restful_client = restful_client.new
    end

    def validate!
      response = restful_client.validate(license)
      response.data || raise(ChefLicensing::InvalidLicense, response.message)
    end

    def licenses_expired?
      # TODO api call to validate expiry of inspec license
      # Dummy boolean value true
      true
    end

    def licenses_about_to_expire?
      # TODO api call to validate about to expire date of inspec license
      # Dummy boolean value true
      true
    end

    private

    attr_reader :restful_client
  end
end