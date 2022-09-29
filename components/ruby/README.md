# Chef Licensing

Ruby support for Progress Chef License Key:
 * Storage ( TODO )
 * ##Generation
   ### Summary
    LicenseKey generation abstracts a RESTful action from the License Server. It is build to raise Exceptions
   ###Usage
   ```ruby
        require 'license_key_generator'
        ChefLicensing::LicenseKeyGenerator.generate!(
            first_name: "FIRSTNAME", 
            last_name: "LASTNAME", 
            email_id: "EMAILID",
            product: "PRODUCT",
            company: "COMPANY", 
            phone: "PHONE"
        )
     ```
   ### Errors
      ```ruby
        ChefLicensing::LicenseGenerationFailed
      ```
    
 * ##Validation 
   ###Usage
   ```ruby
      require 'license_key_validator'
      ChefLicensing::LicenseKeyValidator.validate!("LICENSE_KEY")
   ```

 * Entitlement ( TODO )

## Usage

Docs TODO

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

