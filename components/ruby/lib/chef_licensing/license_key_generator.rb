require_relative "restful_client/v1"
require_relative "exceptions/license_generation_failed"

module ChefLicensing
  class LicenseKeyGenerator
    attr_reader :payload

    class << self
      # @param [Hash] KWARGS keys accepted are [first_name, last_name, email_id, product, company, phone]
      def generate!(kwargs, cl_config: nil)
        new(kwargs, cl_config: cl_config).generate!
      end

      def generate_free_license!(kwargs, cl_config: nil)
        new(kwargs, cl_config: cl_config).generate_free_license!
      end
    end

    def initialize(kwargs, restful_client: ChefLicensing::RestfulClient::V1, cl_config: nil)
      # TODO: validate kwargs
      @payload = build_payload_from(kwargs)
      @restful_client = restful_client.new(cl_config: cl_config)
    end

    def generate!
      response = restful_client.generate_license(payload)
      # need some logic around delivery
      # how the delivery is decided?
      response.licenseId
    rescue RestfulClientError => e
      raise ChefLicensing::LicenseGenerationFailed, e.message
    end

    def generate_free_license!
      # TODO integration with free license generation api
      raise ChefLicensing::LicenseGenerationFailed, "Free license generation is not yet implemented!"
    rescue RestfulClientError => e
      raise ChefLicensing::LicenseGenerationFailed, e.message
    end

    private

    attr_reader :restful_client

    def build_payload_from(kwargs)
      kwargs.slice(:first_name, :last_name, :email_id, :product, :company, :phone)
    end
  end
end