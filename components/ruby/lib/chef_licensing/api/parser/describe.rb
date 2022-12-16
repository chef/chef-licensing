module ChefLicensing
  module Api
    module Parser
      class Describe

        attr_reader :data

        def initialize(data)
          @data = data
        end

        def parse_id
          # TODO
        end

        def parse_license_type
          # TODO
        end

        def parse_status
          # TODO
        end

        # Parse expiration details

        def parse_expiration_date
          # TODO
        end

        def parse_license_expiration_status
          # TODO
        end

        # Parse usage details

        def parse_usage_status
          # TODO
        end

        def parse_usage_limit
          # TODO
        end

        def parse_usage_measure
          # TODO
        end

        def parse_used
          # TODO
        end

        # Parse entitlements

        def parse_feature_entitlements
          # TODO
        end

        def parse_software_entitlements
          # TODO
        end

        def parse_asset_entitlements
          # TODO
        end
      end
    end
  end
end