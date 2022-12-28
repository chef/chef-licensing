module ChefLicensing
  module Api
    module Parser
      class Client

        # Uses response from /client API
        # This parser formats the response which will enable creation of license data object.

        attr_reader :data, :client_data

        def initialize(data)
          # API call response
          @data = data
          @client_data = data["Client"] || {}
        end

        def parse_id
          nil
        end

        def parse_license_type
          client_data["license"]
        end

        def parse_status
          client_data["status"]
        end

        # Parse expiration details

        def parse_expiration_date
          client_data["changesOn"]
        end

        def parse_license_expiration_status
          client_data["changesTo"]
        end

        # Parse usage details
        def parse_limits
          if client_data.empty?
            []
          else
            [{
              "usage_status" => client_data["usage"],
              "usage_limit" => client_data["limit"],
              "usage_measure" => client_data["measure"],
              "used" => client_data["used"],
            }]
          end
        end

        # Parse entitlements

        def parse_feature_entitlements
          data["Features"] || []
        end

        def parse_software_entitlements
          if data["Entitlement"].nil? || data["Entitlement"].empty?
            []
          else
            require "date"
            entitlement_status = (data["Entitlement"]["end"] >= Date.today.to_s) ? "active" : "expired"
            [data["Entitlement"].merge!({ "status" => entitlement_status })] # sending status based on end date
          end
        end

        def parse_asset_entitlements
          data["Assets"] || []
        end
      end
    end
  end
end