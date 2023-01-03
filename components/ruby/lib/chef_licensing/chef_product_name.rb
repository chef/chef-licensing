module ChefLicensing
  def self.chef_product_name
    # TODO - Implement a "strategy"-based system that accepts CHEF_PRODUCT_NAME and --chef-product-name
    # For now, we fetch from ENV with NO DEFAULT.
    ENV.fetch("CHEF_PRODUCT_NAME")
  end
end
