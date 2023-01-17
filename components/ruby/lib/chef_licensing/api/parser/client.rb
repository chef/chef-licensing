require "ostruct" unless defined?(OpenStruct)
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
          @client_data = data.client || OpenStruct.new({})
        end

        def parse_id
          nil
        end

        def parse_license_type
          client_data.license
        end

        def parse_status
          client_data.status
        end

        # Parse expiration details

        def parse_expiration_date
          client_data.changesOn
        end

        def parse_license_expiration_status
          client_data.changesTo
        end

        # Parse usage details
        def parse_limits
          if data.client.nil? || data.client.empty?
            []
          else
            [{
              "usage_status" => client_data.usage,
              "usage_limit" => client_data.limit,
              "usage_measure" => client_data.measure,
              "used" => client_data.used,
            }]
          end
        end

        # Parse entitlements

        def parse_feature_entitlements
          features = []
          features_data = data.features || []
          features_data.each do |feature|
            feature_info = {
              "id" => feature.id,
              "name" => feature.name,
            }
            features << feature_info
          end
          features
        end

        def parse_software_entitlements
          if data.entitlement.nil? || data.entitlement.empty?
            []
          else
            require "date"
            entitlement_status = (data.entitlement.end >= Date.today.to_s) ? "Active" : "Expired"
            # sending status based on end date
            [{
              "id" => data.entitlement.id,
              "name" => data.entitlement.name,
              "entitled" => data.entitlement.entitled,
              "status" => entitlement_status,
            }]
          end
        end

        def parse_asset_entitlements
          assets = []
          assets_data = data.assets || []
          assets_data.each do |asset|
            asset_info = {
              "id" => asset.id,
              "name" => asset.name,
            }
            assets << asset_info
          end
          assets
        end
      end
    end
  end
end