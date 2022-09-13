require_relative "restful_client/v1"
require_relative "exceptions/license_generation_failed"

module ChefLicensing
  class LicenseKeyGenerator
    attr_reader :payload

    def initialize(kwargs, restful_client: ChefLicensing::RestfulClient::V1)
      # TODO: validate kwargs
      @payload = build_payload_from(kwargs)
      @restful_client = restful_client.new
    end

    def generate!
      response = restful_client.generate_license(payload)
      # need some logic around delivery
      # how the delivery is decided?
      response.key
    rescue RestfulClientError => e
      raise ChefLicensing::LicenseGenerationFailed
    end

    private

    attr_reader :restful_client

    def build_payload_from(kwargs)
      {
        firstName: kwargs[:first_name],
        lastName: kwargs[:last_name],
        emailId:  kwargs[:email_id],
        product:  kwargs[:product],
        company:  kwargs[:company],
        phone:    kwargs[:phone],
      }
    end
  end
end