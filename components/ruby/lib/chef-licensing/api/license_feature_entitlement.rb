require_relative "../restful_client/v1"

module ChefLicensing
  module Api
    class LicenseFeatureEntitlement
      attr_reader :license_keys

      class << self
        def check_entitlement!(license_keys: [], feature_name: nil, feature_id: nil)
          new(license_keys: license_keys, feature_name: feature_name , feature_id: feature_id).check_entitlement!
        end
      end

      def initialize(license_keys: [], feature_name: nil, feature_id: nil, restful_client: ChefLicensing::RestfulClient::V1)
        license_keys || raise(ArgumentError, "Missing Params: `license_keys`")
        @license_keys = license_keys.is_a?(Array) ? license_keys : [license_keys]
        @feature_name = feature_name
        @feature_id = feature_id
        raise ArgumentError, "Either of `feature_id` or `feature_name` should be provided" if feature_name.nil? && feature_id.nil?

        @restful_client = restful_client.new
      end

      def check_entitlement!
        response = make_request
        response.data.entitled || raise(ChefLicensing::FeatureNotEntitled)
      end

      private

      attr_reader :restful_client, :feature_id, :feature_name

      def make_request
        payload = build_payload
        if feature_name
          restful_client.feature_by_name(payload)
        else
          restful_client.feature_by_id(payload)
        end
      end

      def build_payload
        {
          licenseIds: license_keys,
        }.tap do |payload|
          if feature_name
            payload[:featureName] = feature_name
          else
            payload[:featureGuid] = feature_id
          end
        end
      end
    end
  end
end