module ChefLicensing
  class Config
    LICENSING_SERVER = ENV.fetch("LICENSING_SERVER")
  end
end
