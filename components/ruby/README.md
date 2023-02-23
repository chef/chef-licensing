# Chef Licensing

Chef Licensing is a Ruby library for managing the licensing of Chef products. It provides the support to generate and validate license keys, as well as track entitlements associated with the licenses. 


## Table of Contents

1. [System Prerequisites](#system-prerequisites)
2. [Installation](#installation)
3. [Usage Prerequisites](#usage-prerequisites)
4. [Usage](#usage)
5. [APIs](#apis)
6. [Implementation Details](#implementation-details)


## System Prerequisites

Usage of this library assumes the system to meet the following requirements:
- **Ruby**: This library requires Ruby version 2.7 or higher. If you do not have Ruby installed, you can download it from the official Ruby website or use a package manager for the same.
- **Bundler**: This project uses Bundler to manage dependencies. If you do not have Bundler installed, you can install it by running the following command in your terminal:
  ```
  gem install bundler
  ```
If you have any issues with the installation or configuration of these prerequisites, please refer to the documentation of each respective tool or library.

## Installation

You can use Chef Licensing Library by adding it to your Gemfile:

<!-- I am assuming the gem name here; we could change it later -->
```ruby
gem 'chef-licensing'
```

Then, run `bundle install` to install the library and its dependencies.


<!-- Usage Prerequisites contains the configuration to be done before using the library in the client's application -->
## Usage Prerequisites

To use the Chef licensing library, certain configuration values such as the server URL, server API key, etc. must be set to generate, validate, and check for entitlements. These values can be set via the environment or the library, or passed as arguments while executing your application.

### Configurations of Chef Licensing Library

The `ChefLicensing::Config` class manages the configuration parameters used in the Chef Licensing library.

<!-- Discuss with team to find which are the optional other than air_gap and logger -->

#### Configure the Parameters using argument flag or environment variable

| Configuration Parameters | Argument Flag | Environment Variable | Type |
|----------|----------|----------|----------|
| license_server_url | `--chef-license-server` | `CHEF_LICENSE_SERVER` | String |
| license_server_api_key | `--chef-license-server-api-key`| `CHEF_LICENSE_SERVER_API_KEY` | String |
| chef_product_name | `--chef-product-name` | `CHEF_PRODUCT_NAME` | String |
| chef_entitlement_id | `--chef-entitlement-id` | `CHEF_ENTITLEMENT_ID` | String |
| air_gap_detected? | `--airgap`  | `CHEF_AIR_GAP` | Boolean |
| logger | - | - | - |

#### Configure the Parameters directly in your Application

```ruby
require "chef_licensing"

ChefLicensing.configure do |config|
  config.license_server_url = "https://license.chef.io"
  config.license_server_api_key = "1234567890"
  config.air_gap_status = false
  config.chef_product_name = "chef"
  config.chef_entitlement_id = "chef123"
  config.logger = Logger.new($stdout)
end

```

<!-- Usage section contains all the methods that the client would invoke while using the Chef Licensing Library -->
## Usage

<!-- Need to create a method for fetch_and_persist maybe? So that all the methods to be used by the client of this library is in one place -->

### Software Entitlement Check

Software entitlement check validates a user's entitlement to use a specific software product by verifying their licenses.

```ruby
require "chef_licensing"
ChefLicensing.check_software_entitlement!
```
#### Response

If the software is entitled to the license, it returns true; else, it raises an `ChefLicensing::SoftwareNotEntitled` exception.

### Feature Entitlement Check

Feature entitlement check validates a premium feature access by verifying it against the user's licenses.

```ruby
require "chef_licensing"
ChefLicensing.check_feature_entitlement!('FEATURE_NAME OR FEATURE_ID')
```

#### Response

If the feature is entitled to one of the provided licenses, it returns true; else, it raises one of the below two exceptions:

- `ChefLicensing::InvalidLicense`: in case of invalid license
- `ChefLicensing::FeatureNotEntitled`: in case of invalid entitlements

### List Licenses Information

List licenses information retrieves detailed information about licenses stored on the system or passed as an argument. It can be used to verify information such as the license type, expiration date, owner, and features associated with each license.

```ruby
require "chef_licensing"
ChefLicensing.list_license_keys_info
```

#### Response

If the retrieval is successful, it displays the information of all the license; else it raises an `ChefLicensing::DescribeError` exception with the error message.

**Sample output:**

```
+---------- License Keys Information ----------+
Total License Keys found: 1

License Key     : guid
Type            : testing
Status          : active
Expiration Date : 2023-12-02

Software Entitlements
ID       : guid
Name     : testing
Status   : expired
Entitled : true

Asset Entitlements
ID       : guid
Name     : testing
Status   : expired
Entitled : true

Feature Entitlements
ID       : guid
Name     : testing
Status   : expired
Entitled : true

License Limits
Usage Status  : Active
Usage Limit   : 2
Usage Measure : 2
Used          : 2
Software      : 
+----------------------------------------------+
```

## APIs

The following APIs provide an abstraction layer for the RESTful actions that are available through the licensing server. These APIs enable various operations such as validation, generation, and others to be performed.
### Generate License Key

It helps to generate a license.

```ruby
require 'chef_licensing/license_key_generator'

ChefLicensing::LicenseKeyGenerator.generate!(
  first_name: "John",
  last_name: "Doe",
  email_id: "johndoe@progress.com",
  product: "inspec",
  company: "Progress",
  phone: "000-000-0000"
)
```
<!-- Give examples for the possible value for product in this example, maybe? -->

#### Response

If successful, the license key generation process responds with a valid license key.
<!-- Add about the location maybe? -->

However, in case of errors, the `ChefLicensing::LicenseGenerationFailed` class returns the message directly from the license generation server as the exception message.

### Validate License Key

It helps to validate array of licenses.

```ruby
require 'chef_licensing/license_feature_entitlement'
ChefLicensing::LicenseKeyValidator.validate!("LICENSE_KEY")
```
#### Response

If the license validation process is successful, it returns true or false to indicate the validity of the license. 

However, if an error occurs during the validation process, the `ChefLicensing::InvalidLicense` class raises an exception message.

### Client

It helps to retrieve information about licenses, its entitlements to various features, software, and assets, as well as details about its expiration date and post-expiry status, and usage information for the license.

```ruby
require "chef_licensing/api/client"
ChefLicensing::Api::Client.info(options_hash)
```
- values to be sent in `options_hash` are `license_keys` and `restful_client`. Default value of restful_client is `ChefLicensing::RestfulClient::V1`.

#### Response

If the retrieval is successful, it returns a license data model object that utilizes the JSON data retrieved from the Licensing Server API.

However, if an error occurs during the process, the `ChefLicensing::ClientError` raises an exception.

**Sample response from the Licensing Server which is converted into license data model object**

```json
{
  "cache": {
    "lastModified": "date",
    "evaluatedOn": "date",
    "expires": "date",
    "cacheControl": "date"
  },
  "client": {
    "license": "Trial|Event|Free|Commercial",
    "status": "Active|Grace|Expired",
    "changesTo": "Grace|Expired",
    "changesOn": "date",
    "changesIn": "xxxx (days)",
    "usage": "Active|Grace|Exhausted",
    "used": "number",
    "limit": "number",
    "measure": "number"
},
  "assets": [{"id": "guid", "name": "string"}],
  "features": [ {"id": "guid", "name": "string"}],
  "entitlement": {
    "id": "guid",
    "name": "string",
    "start": "date",
    "end": "date",
    "licenses": "number",
    "limits": [ {"measure": "string", "amount": "number"} ],
    "entitled": "boolean"
  }
}
```

### Describe

It helps to retrieve information about a list of licenses, including their entitlements to various features, software, and assets, as well as usage limits for each license.

```ruby
require "chef_licensing/api/describe"
ChefLicensing::Api::Describe.list(options_hash)
```

- values to be sent in `options_hash` are `license_keys` and `restful_client`. Default value of `restful_client` is `ChefLicensing::RestfulClient::V1`.

#### Response

If the retrieval is successful, it returns a license data model object that utilizes the JSON data retrieved from the Licensing Server API.

However, if an error occurs during the process, the `ChefLicensing::DescribeError` raises an exception.

**Sample response from the Licensing Server which is converted into license data model object**

```json
{
  "license": [{
    "licenseKey": "guid",
    "serialNumber": "testing",
    "name": "testing",
    "status": "active",
    "start": "2022-12-02",
    "end": "2023-12-02",
    "limits": [
        {
        "testing": "software",
          "id": "guid",
          "amount": 2,
          "measure": 2,
          "used": 2,
          "status": "Active",
        },
      ],
    },
  ],
  "Assets": [
    {
      "id": "guid",
      "name": "testing",
      "entitled": true,
      "from": [
        {
            "license": "guid",
            "status": "expired",
        },
      ],
    }
  ],
  "Software": [
    {
      "id": "guid",
      "name": "testing",
      "entitled": true,
      "from": [
        {
            "license": "guid",
            "status": "expired",
        },
      ],
    },
  ],
  "Features": [
    {
      "id": "guid",
      "name": "testing",
      "entitled": true,
      "from": [
        {
            "license": "guid",
            "status": "expired",
        },
      ],
    },
  ],
  "Services": [
    {
      "id": "guid",
      "name": "testing",
      "entitled": true,
      "from": [
        {
            "license": "guid",
            "status": "expired",
        },
      ],
    },
  ],
}
```

## Implementation Details

This section includes some implementation details of the Chef Licensing library.