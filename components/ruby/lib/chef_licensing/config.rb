module ChefLicensing
  class Config
    LICENSING_SERVER = ENV.fetch("CHEF_LICENSING_SERVER", "https://licensing.chef.co/License/")
  end
end
