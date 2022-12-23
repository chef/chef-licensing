module ChefLicensing
  module Api
    module Parser
      class Describe

        # Uses response from /describe API
        # This parser formats the response which will enable creation of license data object.

        attr_reader :data, :license_data

        def initialize(data)
          @data = data
          @license_data = data["license"] || {}
        end

        def parse_id
          license_data["licenseKey"]
        end

        def parse_license_type
          license_data["name"]
        end

        def parse_status
          license_data["status"]
        end

        # Parse expiration details

        def parse_expiration_date
          license_data["end"]
        end

        def parse_license_expiration_status
          nil
        end

        # Parse usage details

        def parse_limits
          limits = []
          license_data["limits"].each do |limit|
            limit_details = {
              "usage_status" => limit["status"],
              "usage_limit" => limit["amount"],
              "usage_measure" => limit["measure"],
              "used" => limit["used"],
              "software" => limit["software"],
            }
            limits << limit_details
          end
          limits
        end

        # Parse entitlements

        def parse_feature_entitlements
          features = []
          data["features"].each do |feature|
            feature["from"].each do |from_info|
              if from_info["license"] == parse_id
                feature.merge!( { "status" => from_info["status"] } )
                feature.delete("from")
                features << feature
              end
            end
          end
          features
        end

        def parse_software_entitlements
          softwares = []
          data["software"].select do |software|
            software["from"].each do |from_info|
              if from_info["license"] == parse_id
                software.merge!( { "status" => from_info["status"] } )
                software.delete("from")
                softwares << software
              end
            end
          end
          softwares
        end

        def parse_asset_entitlements
          assets = []
          data["assets"].select do |asset|
            asset["from"].each do |from_info|
              if from_info["license"] == parse_id
                asset.merge!( { "status" => from_info["status"] } )
                asset.delete("from")
                assets << asset
              end
            end
          end
          assets
        end
      end
    end
  end
end