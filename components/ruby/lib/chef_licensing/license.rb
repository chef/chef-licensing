require "ostruct" unless defined?(OpenStruct)

# License contain info of license ID, it's type, expiry and different entitlements belonging to it.
# TODO Document this once the specs for API is finalised
module ChefLicensing
  class License

    attr_reader :id, :license_type, :expiry_date, :feature_entitlements, :software_entitlements, :asset_entitlements

    def initialize(opts = {})
      @meta_data = opts[:data]
      @product_name = opts[:product_name]
      @id = fetch_license_id
      @license_type = fetch_license_type
      @expiry_data = fetch_expiry_date

      # TODO To revisit this again after API specs are finalised
      @feature_entitlements = FeatureEntitlements.new(meta_data[:feature_entitlements] || []).list || []
      @software_entitlements = SoftwareEntitlements.new(meta_data[:software_entitlements] || []).list || []
      @asset_entitlements = AssetEntitlements.new(meta_data[:asset_entitlements] || []).list || []
    end

    private

    attr_reader :meta_data, :product_name

    def fetch_license_id
      # TODO fetch license type from meta-data
      @meta_data[:id]
    end

    def fetch_license_type
      # TODO fetch license type from meta-data
      @meta_data[:type]
    end

    def fetch_expiry_date
      # TODO logic to fetch expiry date from meta-data depending on the product
    end

    class FeatureEntitlements
      # License has list of feature entitlements

      attr_reader :list

      def initialize(meta_data)
        @list = meta_data.map { |data| OpenStruct.new(data) }
      end
    end

    class SoftwareEntitlements
      # License has list of software entitlements

      attr_reader :list

      def initialize(meta_data)
        @list = meta_data.map { |data| OpenStruct.new(data) }
      end
    end

    class AssetEntitlements
      # License has list of asset entitlements

      attr_reader :list

      def initialize(meta_data)
        @list = meta_data.map { |data| OpenStruct.new(data) }
      end
    end
  end
end