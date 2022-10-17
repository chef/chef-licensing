# Chef Licensing

Ruby support for fetching, storing, validating, checking entitlement, and interacting with the user about Progress Chef License Keys.

Functionality is divided into several areas:

 * Storing License Keys Locally
 * Interacting with the User (Text UI Engine)
 * Interacting with the Licensing API
 * Checking for an Air Gap
 * Reading a setting for the License Server URL (TODO)

 # Quick Start

 TODO

# Major Components

## Storing License Keys Locally

TODO

## Air Gap Detection

Detecting an air gap condition is needed so that the licensing system can detect when to operate in an offline mode.

Air gap detection may be specified by CLI argument, ENV variable, or by attempting to reach the licensing server through HTTP.

### ChefLicensing.air_gap_detected?

The main entry point to air gap detection is this function. Simply call it, and it will check for (in order) whether the CHEF_AIR_GAP env variable has been set, whether `--airgap` is present in ARGV, and finally whether the Licensing Server URL (its /v1/version endpoint) can be reached by HTTPS. The return value is a boolean, and is cached for the life of the process - airgap detection happens only once.

## TUI Engine

TODO

## Licensing Server API

##Setup
- define the below block in your initializer file `chef-licensing.rb`
   ```ruby
      require 'chef_licensing'
      ChefLicensing.configure do |config|
        config.licensing_server  = 'LICENSE_SERVER'
        config.logger = Logger.new($stdout)
      end
   ```

- Please define the `CHEF_LICENSE_SERVER` env variable to the URL of the Progress Chef License Service you are targeting.

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

