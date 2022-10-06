require_relative "restful_client/v1"
require_relative "exceptions/invalid_entitlement"

module ChefLicensing
  class LicenseFeatureValidator
    attr_reader :licenses

    class << self
      def validate!(licenses, feature_name: nil, feature_id: nil)
        new(licenses, feature_name, feature_id).validate!
      end
    end

    def initialize(licenses, feature_name, feature_id, restful_client: ChefLicensing::RestfulClient::V1)
      licenses || raise(ArgumentError, "Missing Params: `license`")
      @licenses = licenses.is_a?(Array) ? licenses : [licenses]
      @feature_name = feature_name
      @feature_id = feature_id
      raise ArgumentError, "Either of `feature_id` or `feature_name` should be provided" if feature_name.nil? && feature_id.nil?

      @restful_client = restful_client.new
    end

    def validate!
      response = make_request
      response.data.entitled || raise(ChefLicensing::InvalidEntitlement)
    end

    private

    attr_reader :restful_client, :feature_id, :feature_name

    def make_request
      payload = build_payload
      if feature_name
        restful_client.validate_feature_by_name(payload)
      else
        restful_client.validate_feature_by_id(payload)
      end
    end

    def build_payload
      {
        licenseIds: licenses,
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