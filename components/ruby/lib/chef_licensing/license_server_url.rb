# TODO: Delete this file. Not required after config implementation.

module ChefLicensing
  def self.license_server_url
    # TODO - Implement a "strategy"-based system that accepts CHEF_LICENSE_SERVER and --chef-license-server
    # For now, we fetch from ENV with NO DEFAULT
    ENV.fetch("CHEF_LICENSE_SERVER")
  end
end
