require_relative "../restful_client/v1"

module ChefLicensing
  module Api
    class LicenseSoftwareEntitlement
      attr_reader :license_keys

      def self.check!(license_keys: [], software_entitlement_name: nil, software_entitlement_id: nil)
        new(license_keys: license_keys, software_entitlement_name: software_entitlement_name, software_entitlement_id: software_entitlement_id).check!
      end

      def initialize(license_keys: [], software_entitlement_name: nil, software_entitlement_id: nil, restful_client: ChefLicensing::RestfulClient::V1)
        @license_keys = license_keys
        @entitlement_id = software_entitlement_id
        @entitlement_name = software_entitlement_name

        raise ArgumentError, "Either of `software_entitlement_id` or `software_entitlement_name` should be provided" if software_entitlement_name.nil? && software_entitlement_id.nil?

        @restful_client = restful_client.new
      end

      def check!
        response = make_request
        response.data.entitled || raise(ChefLicensing::SoftwareNotEntitled)
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
end