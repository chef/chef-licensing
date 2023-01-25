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

Please define 
- the `CHEF_LICENSE_SERVER` env variable to the URL of the Progress Chef License Service you are targeting.
- the `CHEF_LICENSE_SERVER_API_KEY` env variable of the API key of the Chef License Service.

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

## Client API

Client API contains details of a license and it's entitlement to several features, softwares and assets. It also contains information on expiration date , the status of license after expiration and the license usage details.

### Usage

```ruby
require "chef_licensing"
ChefLicensing.client(license_keys: [LIST_OF_LICENSE_KEYS])
```

or
```ruby
require "chef_licensing/api/license_client"
ChefLicensing::Api::LicenseClient.client(options_hash)
```

where:
- values possible of options_hash are `license_keys` and `restful_client`. Default value of restful_client is `ChefLicensing::RestfulClient::V1`.
- ENV["CHEF_ENTITLEMENT_ID"] needs to be set to fetch value from `ChefLicensing::Config.instance.chef_entitlement_id` or needs to be passed through argument using `--chef-entitlement-id` in CLI.

### Response

Returns an object of license data model which uses JSON data returned from the API.

API JSON response:
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

### Errors

* in case of error in client API it would raise license client error.

```ruby
ChefLicensing::LicenseClientError
```


## Describe API for licenses metadata

Describe API contains details of list of licenses and their entitlements to several features, softwares, assets and the usage limits for each license.

### Usage

```ruby
require "chef_licensing/api/describe"
ChefLicensing::Api::Describe.list(options_hash)
```

where:

- values possible of options_hash are `license_keys` and `restful_client`. Default value of restful_client is `ChefLicensing::RestfulClient::V1`.
- ENV["CHEF_ENTITLEMENT_ID"] needs to be set to fetch value from `ChefLicensing::Config.instance.chef_entitlement_id` or needs to be passed through argument using `--chef-entitlement-id` in CLI.

### Response

Returns a list of objects of license data model which uses JSON data returned from the API.

API JSON response:

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

### Errors

* in case of error in describe API it would raise license describe error.

```ruby
ChefLicensing::DescribeError
```

# TUI Engine

TUI Engine helps to build a text user interface considering each step involved in the text user interface as interaction.

## Syntax

A basic interaction is described as below:
```YAML
interactions:
  start:
    messages: "The message to be displayed in this interaction"
    prompt_type: "say"
    paths: [exit]
    description: "Some description about this interaction"

  exit:
    messages: "Thank you"
```

### Keys in an Interaction File
The different keys in an interaction file are:

1. `interactions`: `interactions` key is the parent key in an interaction file. Every interaction must be defined under this key.

2. `<interaction_id>`: `<interaction_id>` key is the identifier of any interaction, which defines a particular interaction.

   Evert interaction file must have the `start` and `exit` interaction.
   The flow of interaction starts from the `start` interaction and always ends on `exit` interaction.

3. `messages`:  `messages` key contains the texts to be displayed to the user at each interaction. `messages` can receive texts as an array or a string.

   For general purpose display, texts can be provided as string. 

   - Example: `messages: "This is the text to be displayed"`

   Or it could be even provided as an array, and only the message at zeroth index would be picked.

   - Example: `messages: ["This is the text to be displayed"]`

   However, we need to provided the texts as an array or arrays when the provided text is to be displayed as menu. The format to be followed is as: `[header, [choices]]`

   - Example: `messages: ["The header of the menu", ["Option 1", "Option 2"]]`
   
4. `prompt_type`: `prompt_type` key defines the type of prompt for an interaction. The supported prompt types are:

   - `say`: displays the message, returns nil
   - `yes`: displays the message, asks for input from user. Returns true when input is given as `yes` or `y`, and false on input of `no` or `n`.
   - `ok`: displays the message in green color, returns the message.
   - `warn` displays the message in yellow/orange color, returns the message.
   - `error`: displayes the message in red color, returns the message.
   - `select`: displays the menu header and choices, returns the selected choice.
   - `enum_select`: displays the menu header and choices, returns the selected choice.
   - `ask`: displays the message, returns the input value.
   - `timeout_yes`: wraps the `yes` prompt with timeout feature. Default timeout duration is 60 seconds. However, the timeout duration and timeout message can be changed by providing the custom value in `prompt_attributes` key.
   - `timeout_select`: wraps the `select` prompt with timeout feature. Default timeout duration is 60 seconds. However, the timeout duration and timeout message can be changed by providing the custom value in `prompt_attributes` key.

   This key is an optional and defaults to prompt_type of `say`.

5. `paths`: `paths` key accepts an array of interaction id to which an interaction could be follow, after the current responsibility of the interaction is complete. Every interaction must have a path except for the `exit` interaction.

6. `action`: `action` key accepts a method name to be executed for an interaction. The methods are to be defined in `TUIActions` class.

7. `response_path_map`: `response_path_map` key contains a mapping of `<response>: <interaction id>` which helps an interaction in decision making for next interaction.

   The response could be from either prompt display or from action, but not both.

8. `description`: `description` is an optional field of an interaction which is used to describe interaction for readability of the interaction file.

9. `prompt_attributes`: `prompt_attributes` helps to provide additional properties required by any prompt_type. Currently, supported attributes are:
   1.  `timeout_duration`: This attribute is supported by the `timeout_yes` prompt and can receive decimal values.
   2.  `timeout_message`: This attribute is supported by the `timeout_yes` prompt and can receive string values.

10. `:file_format_version`: it defines the version of the interaction file's format. This key is a mandatory key in an interaction file. Currently supported version of interaction file is `1.x.x`

### Ways to define an interaction

The different ways how we can define an interaction is shown below.

1. A simple interaction which displays message and exits with exit message.
   ```YAML
   interactions:
      start:
        messages: "The message to be displayed in this interaction"
        prompt_type: "say"
        paths: [exit]
        description: "Some description about this interaction"

       exit:
         messages: "Thank you"
         prompt_type: "say"
         paths: []
         description: "This is the exit interaction"
   ```
   Here, `start` and `exit` are the interaction id.

   Since, prompt_type defaults to say for any interaction, description is an optional field and paths is empty for `exit` interaction. The above interactions interaction could also be defined as:
   ```YAML
   interactions:
      start:
        messages: "The message to be displayed in this interaction"
        paths: [exit]

       exit:
         messages: "Thank you"
   ```

2. An interaction which displays message and has a single path
   ```YAML
   ask_number:
     messages: "Please enter two numbers"
     prompt_type: "ask"
     paths: [validate_number]
     description: "Some description about this interaction"
   ```
   Here, validate_number is the interaction id of next interaction.

3. An interaction which has an action item and has a single path
   ```YAML
   validate_number:
     action: is_number_valid?
     paths: [add_inputs]
     description: "Some description about this interaction"
   ```
   Here, add_inputs is the interaction id of next interaction.

4. An interaction which displays a list of choices and has multiple paths
   ```YAML
   menu_prompt:
    messages: ["Header of message", ["Option 1", "Option 2"]]
    prompt_type: "select"
    paths: [prompt_1_id, prompt_2_id]
    response_path_map:
      "Option 1": prompt_1_id
      "Option 2": prompt_2_id
   ```
   Here, a menu is displayed with two options to select from. prompt_1_id and prompt_2_id are the two interaction id of next possible interactions. Here, `response_path_map` is required since different response from the user can lead to different interaction.


5. An interaction which has an action item and has multiple paths
   ```YAML
   validate_number:
     action: is_number_valid?
     paths: [add_inputs, ask_number]
     response_path_map:
       "true": add_inputs
       "false": ask_number
      description: "is_number_valid? is a method and should be defined by the user in TUI Actions"
   ```
   Here, after the action is performed, based on the response of the action it could lead to different paths with the mapped interaction id.

## Troubleshooting
- Do not have response_path_map based on the response from prompts and action together in a single interaction, this could lead to ambiguity. So, atomize the interaction to either: 
  - display message,
  - take inputs from user, or
  - to perform an action item
- Prompt_type field defaults to say when not provided. So, mentioning correct prompt_type for menu, choices or taking input is necessary.
- It is recommended to key the keys in response_path_map as strings when key is space separated to maintain the consistency between different type of response.
- Any additional keys provided in the interaction file is ignored.
- Paths is mandatory for all interactions except for `exit` interaction.

## Example of a basic interaction file
```YAML
:file_format_version: 1.0.0

interactions:
  start:
    messages: ["This is a start message"]
    prompt_type: "say"
    paths: [prompt_2]
    description: This is an optional field. WYOD (Write your own description)

  prompt_2:
    messages: ["Do you agree?"]
    prompt_type: "yes"
    paths: [prompt_3, prompt_4]
    response_path_map:
      "true": prompt_3
      "false": prompt_4

  prompt_3:
    messages: ["This is message for prompt 3 - Reached when user says yes"]
    prompt_type: "ok"
    paths: [prompt_6]

  prompt_4:
    messages: ["This is message for prompt 4 - Reached when user says no"]
    prompt_type: "warn"
    paths: [prompt_5]

  prompt_5:
    messages: ["This is message for prompt 5"]
    prompt_type: "error"
    paths: [exit]

  prompt_6:
    messages: ["This is message for prompt 6"]
    prompt_type: "ask"
    paths: [exit]

  exit:
    messages: ["This is the exist prompt"]
    prompt_type: "say"
```

## Example with timeout_yes prompt
```YAML
:file_format_version: 1.0.0

interactions:
  start:
    messages: ["Shall we begin the game?"]
    prompt_type: "timeout_yes"
    prompt_attributes:
      timeout_duration: 10
      timeout_message: "Oops! Reflex too slow."
    paths: [play, rest]
    response_path_map:
      "true": play
      "false": rest
  play:
    messages: ["Playing..."]
    prompt_type: "ok"
    paths: [exit]
  rest:
    messages: ["Resting..."]
    prompt_type: "ok"
    paths: [exit]
  exit:
    messages: ["Game over!"]
    prompt_type: "say"
```

## Example with erb message
```YAML
:file_format_version: 1.0.0

interactions:
  start:
    messages: ["TUI GREET!"]
    prompt_type: "say"
    paths: [ask_user_name]
    description: This is an optional field. WYOD (Write your own description)
  ask_user_name:
    messages: ["What is your name?"]
    prompt_type: "ask"
    paths: [welcome_user_in_english]
    description: This is an optional field. WYOD (Write your own description)
  welcome_user_in_english:
    # You can provide variables/Constants of TUIEngineState
    messages: ["Hello, <%=  input[:ask_user_name] %>"]
    prompt_type: "ok"
    paths: [exit]
  exit:
    messages: ["This is the exit prompt"]
    prompt_type: "say"
```

## Example with timeout_select prompt
```YAML
interactions:
  start:
    messages: ["Shall we begin the game?", ["Yes", "No", "Exit"]]
    prompt_type: "timeout_select"
    prompt_attributes:
      timeout_duration: 10
      timeout_message: "Oops! Your reflex is too slow."
    paths: [play, rest, exit]
    response_path_map:
      "Yes": play
      "No": rest
      "Exit": exit

  play:
    messages: ["Playing..."]
    prompt_type: "ok"
    paths: [exit]
    description: WYOD.

  rest:
    messages: ["Resting..."]
    prompt_type: "ok"
    paths: [exit]
    description: WYOD.

  exit:
    messages: ["Game over!"]
    prompt_type: "say"
```

# License Data Model

## Summary:

License data model is a license object created from the license data received in different formats from `/client` and `/describe` API.

## License Data Model Creation Syntax:

```ruby
require "chef_licensing/license"

ChefLicensing::License.new(
  data: CLIENT_API_RESPONSE,
  api_parser: ChefLicensing::Api::Parser::Client
)
```

OR

```ruby
require "chef_licensing/license"

ChefLicensing::License.new(
  data: DESCRIBE_API_RESPONSE_FOR_EACH_LICENSE,
  api_parser: ChefLicensing::Api::Parser::Describe
)
```

where:

- **CLIENT_API_RESPONSE** should contain `Client`, `Features`, `Entitlement` & `Assets` keys for proper object creation.
- **DESCRIBE_API_RESPONSE_FOR_EACH_LICENSE** should contain `license`, `features` `software` & `assets` keys for proper object creation.
- ENV["CHEF_PRODUCT_NAME"] needs to be set to fetch value from `ChefLicensing::Config.instance.chef_product_name` or needs to be passed through argument using `--chef-product-name` in CLI.
- The `/describe` API is the metadata of all licenses and it is a list. Therefore, license data model should be called by iterating over the list of licenses. And data of each license should be passed with a mandatory `license` key.

## License Data Model Attributes:

On success, license data model contains these attributes:

- `id` is license key value.
- `license_type` is the type of license (Trial, Free, Commercial).
- `status` can have values like `Active`, `Expired` or `Grace`.
- `expiration_date` is the date after which license will be expired.
- `expiration_status` is the status of the license post expiration. It could be with `Expired` or `Grace`.
- `feature_entitlements` is the list of features which are entitled to the license. It contains attributes `id`, `name`, `entitled` and `status`.
- `software_entitlements` is the list of softwares which are entitled to the license. It contains attributes `id`, `name`, `entitled` and `status`.
- `asset_entitlements` is the list of assets which are entitled to the license. It contains attributes `id`, `name`, `entitled` and `status`.
- `limits` is the list of information around license usage, measure, limits and used info for different softwares. It contains attributes `usage_status`, `usage_limit`, `usage_measure`, `used` and `software`.
