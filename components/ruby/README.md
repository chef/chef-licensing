# Chef Licensing

Ruby support for Progress Chef License Key:
##Pre-requisites
- please define the `LICENSING_SERVER` env variables

 * Storage ( TODO )
 * ##Generation
   ### Summary
    LicenseKey generation abstracts a RESTful action from the License Server. It raises Exceptions when license generation fails
   ###Usage
   ```ruby
        require 'chef_licensing/license_key_generator'
        ChefLicensing::LicenseKeyGenerator.generate!(
            first_name: "FIRSTNAME", 
            last_name: "LASTNAME", 
            email_id: "EMAILID",
            product: "PRODUCT",
            company: "COMPANY", 
            phone: "PHONE"
        )
     ```
   
   ### Response
      on success, it responds with a valid LICENSE KEY and on failure it raises an Error
   ### Errors
      On errors, message from the license gen server is directly return as exception message
      ```ruby
        ChefLicensing::LicenseGenerationFailed
      ```

    
 * ##Validation 
   ###Usage
   ```ruby
      require 'chef_licensing/license_key_validator'
   
      ChefLicensing::LicenseKeyValidator.validate!("LICENSE_KEY")
   ```
   ### Response
     on success, it responds `true` and on failure it raises an Error
   ### Errors
      ```ruby
        ChefLicensing::InvalidLicense
      ```

 * Entitlement
   ## Features Entitlement
   ### Usage
   - License Feature Validator can accept either of Feature Name or Feature ID.
   - Also it can accept multiple License IDs at the same time.
   - the entitlement check would be successful if the feature is entitled by at least one of the given licenses
   
   #### Validate with Single License and Feature ID
   ```ruby
      require 'chef_licensing/license_feature_validator'
   
      ChefLicensing::LicenseFeatureValidator.validate!("LICENSE", feature_id: "FEATURE_ID")
   ```
 
   #### Validate with Multiple license and Feature ID
   ```ruby
      require 'chef_licensing/license_feature_validator'
   
      ChefLicensing::LicenseFeatureValidator.validate!(["LICENSES"], feature_id: "FEATURE_ID")
   ```
   
   #### Validate with Feature Name
   ```ruby
      require 'chef_licensing/license_feature_validator'
   
      ChefLicensing::LicenseFeatureValidator.validate!(["LICENSES"], feature_name: "FEATURE_NAME")
   ```

   ### Response
     on success, it responds `true` meaning the feature is entitled to one of the given licenses 
     and on failure it raises an Error
   ### Errors
   - in case of invalid license it would raise invalid license error
   ```ruby
      ChefLicensing::InvalidLicense
   ```
    - in case of invalid entitlements it would raise an invalid entitlement error
   ```ruby
      ChefLicensing::InvalidEntitlement
   ```


## Usage

Docs TODO

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

