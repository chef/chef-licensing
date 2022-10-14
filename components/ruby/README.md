# Chef Licensing

Ruby support for Progress Chef License Key:
## Pre-requisites

- please define the `CHEF_LICENSE_SERVER` env variable to the URL of the Progress Chef License Service you are targeting.

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

 * Entitlement ( TODO )

## Usage

Docs TODO

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

