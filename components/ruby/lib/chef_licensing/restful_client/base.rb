require "faraday" unless defined?(Faraday)
require_relative "../exceptions/restful_client_error"
require_relative "../config"

module ChefLicensing
  module RestfulClient

    # Base class to handle all License Server endpoints
    class Base

      END_POINTS = {
        VALIDATE: "validate",
        GENERATE_LICENSE: "triallicense",
        FEATURE_BY_NAME: "license-service/featurebyname",
        FEATURE_BY_ID: "license-service/featurebyid",
      }.freeze

      def validate(license)
        handle_connection do |connection|
          connection.get(self.class::END_POINTS[:VALIDATE], { licenseId: license }).body
        end
      end

      def generate_license(payload)
        handle_connection do |connection|
          response = connection.post(self.class::END_POINTS[:GENERATE_LICENSE]) do |request|
            request.body = payload.to_json
          end
          raise RestfulClientError, format_error_from(response) unless response.success?

          response.body
        end
      end

      def feature_by_name(payload)
        handle_connection do |connection|
          response = connection.post(self.class::END_POINTS[:FEATURE_BY_NAME]) do |request|
            request.body = payload.to_json
          end
          raise RestfulClientError, format_error_from(response) unless response.success?

          response.body
        end
      end

      def feature_by_id(payload)
        handle_connection do |connection|
          response = connection.post(self.class::END_POINTS[:FEATURE_BY_ID]) do |request|
            request.body = payload.to_json
          end
          raise RestfulClientError, format_error_from(response) unless response.success?

          response.body
        end
      end

      def handle_connection
        # handle faraday errors
        yield connection
      rescue Faraday::ClientError => e
        # log errors
        raise RestfulClientError, e.message
      end

      private

      def connection
        Faraday.new(url: ChefLicensing::Config::LICENSING_SERVER) do |config|
          config.request :json
          config.response :json, parser_options: { object_class: OpenStruct }
        end
      end

      def format_error_from(response)
        error_details = response.body&.data&.error
        return response.reason_phrase unless error_details

        error_details
      end
    end
  end
end