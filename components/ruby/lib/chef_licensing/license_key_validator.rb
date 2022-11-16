require_relative "restful_client/v1"
require_relative "exceptions/invalid_license"

module ChefLicensing
  class LicenseKeyValidator
    attr_reader :license

    class << self
      def validate!(license)
        new(license).validate!
      end

      def license_expired?(license)
        new(license).license_expired?
      end

      def license_about_to_expire?(license)
        new(license).license_about_to_expire?
      end

      def license_type(license)
        new(license).license_type
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

    def license_expired?
      # TODO api call to validate expiry of inspec license
      # Dummy boolean value true
      true
    end

    def license_about_to_expire?
      # TODO api call to validate about to expire date of inspec license
      # Dummy boolean value true
      true
    end

    def license_type
      # TODO api call to find license type
      # Dummy boolean value commercial for commercial license
      "commercial"
    end

    private

    attr_reader :restful_client
  end
end