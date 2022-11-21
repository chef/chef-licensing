# TODO: Delete this file. Not required after config implementation.

module ChefLicensing
  def self.license_server_api_key
    # TODO - Implement a "strategy"-based system that accepts CHEF_LICENSE_SERVER_API_KEY and --chef-license-server-api-key
    # For now, we fetch from ENV with NO DEFAULT
    ENV.fetch("CHEF_LICENSE_SERVER_API_KEY")
  end
end