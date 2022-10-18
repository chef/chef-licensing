# Chef Licensing

Ruby support for fetching, storing, validating, checking entitlement, and interacting with the User about Progress Chef License Keys.

Functionality is divided into several areas:

* Storing License Keys Locally
* Interacting with the User (Text UI Engine)
* Interacting with the Licensing API
* Checking for an Air Gap
* Reading a setting for the License Server URL (TODO)

## Quick Start

TODO

## Major Components

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

### Pre-requisites

Please define the `CHEF_LICENSE_SERVER` env variable to the URL of the Progress Chef License Service you are targeting.

## Storage

## License Generation

### Summary:

LicenseKey generation abstracts a RESTful action from the License Server. It raises Exceptions when license generation fails

### License Key Genereation Usage:


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

### License Key Genereation Response:

On success, it responds with a valid LICENSE KEY and on failure it raises an Error

### License Key Genereation Errors:

On errors, message from the license gen server is directly return as exception message

```ruby
ChefLicensing::LicenseGenerationFailed
```

## License Validation

### License Validation Usage

```ruby
require 'chef_licensing/license_feature_entitlement'
ChefLicensing::LicenseKeyValidator.validate!("LICENSE_KEY")
```

### License Validation Response

On success, it returns `true` and on failure it raises an Error

### License Validation Exceptions

```ruby
  ChefLicensing::InvalidLicense
```

## Entitlement

## Software Entitlement

Software entitlement check validates the software entitlement against given licenses.

### ChefLicensing.check_software_entitlement

Accepts the software_entitlement_name or software_entitlement_id as parameter.

* check_software_entitlment by name:

```ruby
require "chef_licensing"
ChefLicensing.check_software_entitlement!(software_entitlement_name: "Software-Name")
```

* check_software_entitlment by id:

```ruby
require "chef_licensing"
ChefLicensing.check_software_entitlement!(software_entitlement_id: "Software-ID")
```

* Returns `true` if software is entitled to the license else raises `ChefLicensing::InvalidEntitlement` exception.

### Software Entitlement API service class usage:

* Check with software entitlement name

 ```ruby
require 'chef_licensing/license_software_entitlement'
ChefLicensing::LicenseSoftwareEntitlement.check!(license_keys: license_keys, software_entitlement_name: software_entitlement_name)
```

* Check with software entitlement name

 ```ruby
require 'chef_licensing/license_software_entitlement'
ChefLicensing::LicenseSoftwareEntitlement.check!(license_keys: license_keys, software_entitlement_id: software_entitlement_id)
```

* Returns `true` if software is entitled to the license else raises `ChefLicensing::InvalidEntitlement` exception.

## Features Entitlement

Feature entitlement check allows validating the premium features entitlement against the license.

### ChefLicensing.check_feature_entitlement

Accepts the feature name as the argument

#### check_feature_entitlment usage

```ruby
require "chef_licensing"
ChefLicensing.check_feature_entitlement!('FEATURE_NAME')
```

### Usage of Service class

* License Feature Validator can accept either of Feature Name or Feature ID.
* Also it can accept multiple License IDs at the same time.
* the entitlement check would be successful if the feature is entitled by at least one of the given licenses

#### Validate with Single License and Feature ID

```ruby
require 'chef_licensing/license_feature_entitlement'
ChefLicensing::LicenseFeatureEntitlement.check_entitlement!("LICENSE", feature_id: "FEATURE_ID")
```

#### Validate with Multiple license and Feature ID

```ruby
require 'chef_licensing/license_feature_entitlement'
ChefLicensing::LicenseFeatureEntitlement.check_entitlement!(["LICENSES"], feature_id: "FEATURE_ID")
```

#### Validate with Feature Name

```ruby
require 'chef_licensing/license_feature_entitlement'
ChefLicensing::LicenseFeatureEntitlement.check_entitlement!(["LICENSES"], feature_name: "FEATURE_NAME")
```

### Response

On success, it returns `true` meaning the feature is entitled to one of the given licenses and
on failure it raises an Error

### Errors

* in case of invalid license it would raise invalid license exception

```ruby
ChefLicensing::InvalidLicense
```

* in case of invalid entitlements it would raise an invalid entitlement exception

```ruby
ChefLicensing::InvalidEntitlement
```

## Usage

Docs TODO

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.
