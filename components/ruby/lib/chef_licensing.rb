require "chef_licensing/version"
require "chef_licensing/config"

module ChefLicensing
  class << self

    # @example
    #   ChefLicensing.configure do |config|
    #     config.licensing_server  = 'LICENSE_SERVER'
    #     config.logger = Logger.new($stdout)
    #   end
    def configure(&block)
      yield(ChefLicensing::Config)
    end
  end
end
