require_relative "api/parser/client" unless defined?(ChefLicensing::Api::Parser::Client)
require_relative "api/parser/describe" unless defined?(ChefLicensing::Api::Parser::Describe)
require_relative "config"

# License data model has an id, status, type of license, entitlements and limits.

module ChefLicensing
  class License

    attr_reader :id, :license_type , :status, :expiration_date, :expiration_status
    attr_accessor :number_of_days_in_expiration

    def initialize(opts = {})
      # API parser based on the API call
      @parser = opts[:api_parser].new(opts[:data])
      @product_name = ChefLicensing::Config.chef_product_name

      @id = @parser.parse_id
      @status = @parser.parse_status
      @license_type = @parser.parse_license_type

      # expiration details
      @expiration_date = @parser.parse_expiration_date
      @expiration_status = @parser.parse_license_expiration_status

      # usage details
      @limits = []

      # Entitlements
      @feature_entitlements = []
      @software_entitlements = []
      @asset_entitlements = []
    end

    def feature_entitlements
      return @feature_entitlements unless @feature_entitlements.empty?

      feat_entitlements = []
      feat_entitlements_data = @parser.parse_feature_entitlements
      feat_entitlements_data.each do |data|
        feat_entitlements << FeatureEntitlement.new(data)
      end
      @feature_entitlements = feat_entitlements
    end

    def software_entitlements
      return @software_entitlements unless @software_entitlements.empty?

      sw_entitlements = []
      sw_entitlements_data = @parser.parse_software_entitlements
      sw_entitlements_data.each do |data|
        sw_entitlements << SoftwareEntitlement.new(data)
      end
      @software_entitlements = sw_entitlements
    end

    def asset_entitlements
      return @asset_entitlements unless @asset_entitlements.empty?

      asset_entitlements = []
      asset_entitlements_data = @parser.parse_asset_entitlements
      asset_entitlements_data.each do |data|
        asset_entitlements << AssetEntitlement.new(data)
      end
      @asset_entitlements = asset_entitlements
    end

    def limits
      return @limits unless @limits.empty?

      limits = []
      limits_data = @parser.parse_limits
      limits_data.each do |data|
        limits << Limit.new(data, { product_name: @product_name })
      end
      @limits = limits
    end

    # License has list of limits for different softwares which includes usage details.
    class Limit
      attr_reader :usage_status, :usage_limit, :usage_measure, :used, :software

      def initialize(limit_data, opts = {})
        @usage_status = limit_data["usage_status"]
        @usage_limit = limit_data["usage_limit"]
        @usage_measure = limit_data["usage_measure"]
        @used = limit_data["used"]
        @software = limit_data["software"] || opts[:product_name]
      end
    end

    # License can be entitled to list of features.
    class FeatureEntitlement
      attr_reader :id, :name, :entitled, :status

      def initialize(entitlement_data)
        @id = entitlement_data["id"]
        @name = entitlement_data["name"]
        @entitled = entitlement_data["entitled"]
        @status = entitlement_data["status"]
      end
    end

    # License can be entitled to list of softwares.
    class SoftwareEntitlement
      attr_reader :id, :name, :entitled, :status

      def initialize(entitlement_data)
        @id = entitlement_data["id"]
        @name = entitlement_data["name"]
        @entitled = entitlement_data["entitled"]
        @status = entitlement_data["status"]
      end
    end

    # License can be entitled to list of assets.
    class AssetEntitlement
      attr_reader :id, :name, :entitled, :status

      def initialize(entitlement_data)
        @id = entitlement_data["id"]
        @name = entitlement_data["name"]
        @entitled = entitlement_data["entitled"]
        @status = entitlement_data["status"]
      end
    end

    def have_grace?
      status.eql?("Grace")
    end

    def expired?
      status.eql?("Expired")
    end

    def active?
      status.eql?("Active")
    end

    def expiring_or_expired?
      have_grace? || expired? || about_to_expire?
    end

    def about_to_expire?
      require "Date" unless defined?(Date)
      self.number_of_days_in_expiration = (Date.parse(expiration_date) - Date.today).to_i
      # starts to nag before a week when about to expire
      status.eql?("Active") && expiration_status.eql?("Expired") && ((1..7).include? number_of_days_in_expiration)
    end
  end
end