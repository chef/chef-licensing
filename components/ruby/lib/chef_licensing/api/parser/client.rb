module ChefLicensing
  module Api
    module Parser
      class Client

        attr_reader :data

        def initialize(data)
          # API call response
          @data = data
        end

        def parse_id
          nil
        end

        def parse_license_type
          data["Client"]["license"]
        end

        def parse_status
          data["Client"]["status"]
        end

        # Parse expiration details

        def parse_expiration_date
          data["Client"]["changesOn"]
        end

        def parse_license_expiration_status
          data["Client"]["changesTo"]
        end

        # Parse usage details

        def parse_limits
          [{
            "usage_status" => data["Client"]["usage"],
            "usage_limit" => data["Client"]["limit"],
            "usage_measure" => data["Client"]["measure"],
            "used" => data["Client"]["used"],
          }]
        end

        # Parse entitlements

        def parse_feature_entitlements
          data["Features"]
        end

        def parse_software_entitlements
          [data["Entitlement"]]
        end

        def parse_asset_entitlements
          data["Assets"]
        end
      end
    end
  end
end