require_relative "restful_client/v1"

module ChefLicensing
  class LicenseSoftwareEntitlement
    attr_reader :license_keys

    def self.check!(license_keys, entitlement_name: nil, entitlement_id: nil)
      new(license_keys, entitlement_name, entitlement_id).validate!
    end

    def initialize(license_keys, entitlement_name, entitlement_id, restful_client: ChefLicensing::RestfulClient::V1)
      @license_keys = license_keys
      @entitlement_id = entitlement_id
      @entitlement_name = entitlement_name

      raise ArgumentError, "Either of `entitlement_id` or `entitlement_name` should be provided" if entitlement_name.nil? && entitlement_id.nil?

      @restful_client = restful_client.new
    end

    def validate!
      response = make_request
      response.data.entitled || raise(ChefLicensing::InvalidEntitlement)
    end

    private

    attr_reader :restful_client, :entitlement_id, :entitlement_name

    def make_request
      payload = build_payload
      if entitlement_name
        restful_client.entitlement_by_name(payload)
      else
        restful_client.entitlement_by_id(payload)
      end
    end

    def build_payload
      {
        licenseIds: license_keys,
      }.tap do |payload|
        if entitlement_name
          payload[:entitlementName] = entitlement_name
        else
          payload[:entitlementGuid] = entitlement_id
        end
      end
    end
  end
end