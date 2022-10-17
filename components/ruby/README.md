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

## Pre-requisites

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

 * Entitlement
   ## Features Entitlement
   ### Usage
   - License Feature Validator can accept either of Feature Name or Feature ID.
   - Also it can accept multiple License IDs at the same time.
   - the entitlement check would be successful if the feature is entitled by at least one of the given licenses

   #### Validate the feature for entitlements
   ```ruby
      require "chef_licensing"
      ChefLicensing.check_feature_entitlement!('FEATURE_NAME') 
   ```
   
   #### Validate with Single License and Feature ID
   ```ruby
      require 'chef_licensing/license_feature_validator'
   
      ChefLicensing::LicenseFeatureEntitlement.check_entitlement!("LICENSE", feature_id: "FEATURE_ID")
   ```
 
   #### Validate with Multiple license and Feature ID
   ```ruby
      require 'chef_licensing/license_feature_validator'
   
      ChefLicensing::LicenseFeatureEntitlement.check_entitlement!(["LICENSES"], feature_id: "FEATURE_ID")
   ```
   
   #### Validate with Feature Name
   ```ruby
      require 'chef_licensing/license_feature_validator'
   
      ChefLicensing::LicenseFeatureEntitlement.check_entitlement!(["LICENSES"], feature_name: "FEATURE_NAME")
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

