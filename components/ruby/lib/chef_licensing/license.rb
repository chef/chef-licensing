require "ostruct" unless defined?(OpenStruct)

# License contain info of license ID, it's type, expiry and different entitlements belonging to it.
# TODO Document this once the specs for API is finalised
module ChefLicensing
  class License

    attr_reader :id, :expiry_date, :feature_entitlements, :software_entitlements, :asset_entitlements

    def initialize(opts = {})
      @meta_data = opts[:data]
      @product_name = opts[:product_name]
      @id = fetch_license_id
      @expiry_data = fetch_expiry_date

      # TODO To revisit this again after API specs are finalised
      @feature_entitlements = fetch_feature_entitlements
      @software_entitlements = fetch_software_entitlements
      @asset_entitlements = fetch_asset_entitlements
    end

    private

    attr_reader :meta_data, :product_name

    def fetch_license_id
      # TODO fetch license type from meta-data
      meta_data[:id]
    end

    def fetch_feature_entitlements
      # License has list of feature entitlements
      feat_entitlements = []
      feat_entitlements_data = meta_data[:feature_entitlements] || []
      feat_entitlements_data.each do |data|
        feat_entitlements << FeatureEntitlement.new(data)
      end
      feat_entitlements
    end

    def fetch_software_entitlements
      # License has list of software entitlements
      sw_entitlements = []
      sw_entitlements_data = meta_data[:software_entitlements] || []
      sw_entitlements_data.each do |data|
        sw_entitlements << SoftwareEntitlement.new(data)
      end
      sw_entitlements
    end

    def fetch_asset_entitlements
      # License has list of asset entitlements
      asset_entitlements = []
      asset_entitlements_data = meta_data[:asset_entitlements] || []
      asset_entitlements_data.each do |data|
        asset_entitlements << AssetEntitlement.new(data)
      end
      asset_entitlements
    end

    def fetch_expiry_date
      # TODO logic to fetch expiry date from meta-data depending on the product
    end

    class FeatureEntitlement
      attr_reader :id, :name, :expiry_date

      def initialize(entitlement_data)
        @id = entitlement_data[:id]
        @name = entitlement_data[:name]
        @expiry_date = entitlement_data[:expiry_date]
      end
    end

    class SoftwareEntitlement
      attr_reader :id, :name, :expiry_date, :node, :limit

      def initialize(entitlement_data)
        @id = entitlement_data[:id]
        @name = entitlement_data[:name]
        @expiry_date = entitlement_data[:expiry_date]
        @node = entitlement_data[:node]
        @limit = entitlement_data[:limit]
      end
    end

    class AssetEntitlement
      attr_reader :id, :expiry_date

      def initialize(entitlement_data)
        @id = entitlement_data[:id]
        @expiry_date = entitlement_data[:expiry_date]
      end
    end
  end
end