require "ostruct" unless defined?(OpenStruct)
module ChefLicensing
  module Api
    module Parser
      class Describe

        # Uses response from /describe API
        # This parser formats the response which will enable creation of license data object.

        attr_reader :data, :license_data

        def initialize(data)
          @data = data
          @license_data = data.license || OpenStruct.new({})
        end

        def parse_id
          license_data.licenseKey
        end

        def parse_license_type
          license_data.licenseType
        end

        def parse_status
          license_data.status
        end

        # Parse expiration details

        def parse_expiration_date
          license_data.end
        end

        def parse_license_expiration_status
          nil
        end

        # Parse usage details

        def parse_limits
          limits = []
          limits_data = license_data.limits || []
          limits_data.each do |limit|
            limit_details = {
              "usage_status" => limit.status,
              "usage_limit" => limit.amount,
              "usage_measure" => limit.measure,
              "used" => limit.used,
              "software" => limit.software,
            }
            limits << limit_details
          end
          limits
        end

        # Parse entitlements

        def parse_feature_entitlements
          features = []
          features_data = data.features || []
          features_data.each do |feature|
            feature.from.each do |from_info|
              if from_info.license == parse_id
                feature_details = {
                  "status" => from_info.status,
                  "entitled" => feature.entitled,
                  "id" => feature.id,
                  "name" => feature.name,
                }
                features << feature_details
              end
            end
          end
          features
        end

        def parse_software_entitlements
          softwares = []
          softwares_data = data.software || []
          softwares_data.select do |software|
            software.from.each do |from_info|
              if from_info.license == parse_id
                software_details = {
                  "status" => from_info.status,
                  "entitled" => software.entitled,
                  "id" => software.id,
                  "name" => software.name,
                }
                softwares << software_details
              end
            end
          end
          softwares
        end

        def parse_asset_entitlements
          assets = []
          assets_data = data.assets || []
          assets_data.select do |asset|
            asset.from.each do |from_info|
              if from_info.license == parse_id
                asset_details = {
                  "status" => from_info.status,
                  "entitled" => asset.entitled,
                  "id" => asset.id,
                  "name" => asset.name,
                }
                assets << asset_details
              end
            end
          end
          assets
        end
      end
    end
  end
end