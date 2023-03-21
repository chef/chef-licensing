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
- **Ruby**: This library requires Ruby version >= 3.1. If you do not have Ruby installed, you can download it from the official Ruby website or use a package manager for the same.
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
| output | - | - | - |

where:

- `license_server_url`: the URL of the licensing server
- `license_server_api_key`: the API token/key of the licensing server
- `chef_product_name`: the name of the chef software using this library
- `chef_entitlement_id`: the unique entitlement id of the chef's software
- `air_gap_detected?`: helps detect an air gap condition, which is necessary for the licensing system to determine when to function in an offline mode. An air gap environment is determined to be present if any of the following conditions are met: 
  - the environment variable is set, 
  - the argument flag is provided, 
  - or there is an inability to ping the licensing server URL.

  The return value is a boolean, and is cached for the life of the process - airgap detection happens only once.
- `logger`: sets the logger functionality for the Chef Licensing library. It defaults to `Logger.new(STDERR)` and the logger level as `INFO`
- `output`: sets the output stream for the chef-licensing library. It defaults to `STDOUT` but could be directed the output stream to a file if required.

#### Configure the Parameters directly in your Application

```ruby
require "chef-licensing"

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
<!-- Document about the fetch_and_persist after the wrapper is introduced in the chef-licensing file. -->

### Software Entitlement Check

Software entitlement check validates a user's entitlement to use a specific software product by verifying their licenses.

```ruby
require "chef-licensing"
ChefLicensing.check_software_entitlement!
```
#### Response

If the software is entitled to the license, it returns true; else, it raises an `ChefLicensing::SoftwareNotEntitled` exception.

### Feature Entitlement Check

Feature entitlement check validates a premium feature access by verifying it against the user's licenses.

```ruby
require "chef-licensing"
ChefLicensing.check_feature_entitlement!('FEATURE_NAME OR FEATURE_ID')
```

#### Response

If the feature is entitled to one of the provided licenses, it returns true; else, it raises one of the below two exceptions:

- `ChefLicensing::InvalidLicense`: in case of invalid license
- `ChefLicensing::FeatureNotEntitled`: in case of invalid entitlements

### List Licenses Information

List licenses information retrieves detailed information about licenses stored on the system or passed as an argument. It can be used to verify information such as the license type, expiration date, owner, and features associated with each license.

```ruby
require "chef-licensing"
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

### Add new license

This endpoint enables adding new license to the system by generating a license based on the type of license (trial, free or commercial) selected by the user.

#### Response

If successful, the license key is generated.

However, in case of errors, the `ChefLicensing::LicenseGenerationFailed` class returns the message directly from the license generation server as the exception message.

## APIs

The following APIs provide an abstraction layer for the RESTful actions that are available through the licensing server. These APIs enable various operations such as validation, generation, and others to be performed.
### Generate License Key

It helps to generate a license.

```ruby
require 'chef-licensing/license_key_generator'

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
require 'chef-licensing/license_feature_entitlement'
ChefLicensing::LicenseKeyValidator.validate!("LICENSE_KEY")
```
#### Response

If the license validation process is successful, it returns true or false to indicate the validity of the license. 

However, if an error occurs during the validation process, the `ChefLicensing::InvalidLicense` class raises an exception message.

### Client

It helps to retrieve information about licenses, its entitlements to various features, software, and assets, as well as details about its expiration date and post-expiry status, and usage information for the license.

```ruby
require "chef-licensing/api/client"
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
require "chef-licensing/api/describe"
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

### License Data Model

The license data model is a blueprint class that serves as a representation of the license object, comprising the following attributes:

- `id`: license key value.
- `license_type`: type of license (Trial, Free, Commercial).
- `status`: status of license (`Active`, `Expired` or `Grace`).
- `expiration_date`: expiration date of license
- `expiration_status`: status of the license post expiration. It could be with `Expired` or `Grace`.
- `feature_entitlements`: list of features which are entitled to the license. It contains attributes `id`, `name`, `entitled` and `status`.
- `software_entitlements`: list of softwares which are entitled to the license. It contains attributes `id`, `name`, `entitled` and `status`.
- `asset_entitlements`: list of assets which are entitled to the license. It contains attributes `id`, `name`, `entitled` and `status`.
- `limits`: list of information around license usage, measure, limits and used info for different softwares. It contains attributes `usage_status`, `usage_limit`, `usage_measure`, `used` and `software`.

The object is instantiated using the data received from various formats through the /client and /describe APIs.

#### Usage: Creation Syntax

```ruby
require "chef-licensing/license"

ChefLicensing::License.new(
  data: CLIENT_API_RESPONSE,
  api_parser: ChefLicensing::Api::Parser::Client
)
```

OR

```ruby
require "chef-licensing/license"

ChefLicensing::License.new(
  data: DESCRIBE_API_RESPONSE_FOR_EACH_LICENSE,
  api_parser: ChefLicensing::Api::Parser::Describe
)
```

where:

- **CLIENT_API_RESPONSE** should contain `Client`, `Features`, `Entitlement` & `Assets` keys for proper object creation.
- **DESCRIBE_API_RESPONSE_FOR_EACH_LICENSE** should contain `license`, `features` `software` & `assets` keys for proper object creation.
- The `/describe` API is the metadata of all licenses and it is a list. Therefore, license data model should be called by iterating over the list of licenses. And data of each license should be passed with a mandatory `license` key.

### TUI Engine

The TUI Engine assists in the creation of a text-based user interface by treating each step of the interface as an individual interaction. The TUI Engine is utilized in this library to generate the implemented text user interfaces.

#### Usage

```ruby
require "tui_engine"
tui_engine = ChefLicensing::TUIEngine.new(config)
```

where:

- `config` is a hash which must contain the values `interaction_file` which is the path of yaml file containing the interactions.

Moreover, the message to be presented in the TUI can be dynamic in nature. It can either be received from the user during an interaction or can be directly supplied to the engine for display at a particular prompt using the ERB templating messages. See [examples](#examples) for details.

To supply the dynamic messages to the engine, send a hash as below:

```ruby
tui_engine.append_info_to_input({ extra_info: "Welcome!" })
```
Now extra_info key could be used to display as part of text user interace in the erb template.

Examle: `messages: "This is a dynamic message, <% input[:extra_info] $>`

#### Syntax of an Interaction

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


where the different keys in an interaction file are:

1. `interactions`: `interactions` key is the parent key in an interaction file. Every interaction must be defined under this key.

2. `<interaction_id>`: `<interaction_id>` key is the identifier of any interaction, which defines a particular interaction.

   Every interaction file must have an `exit` interaction.
   The flow of interaction can run from any defined start interaction and always ends on `exit` interaction.

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

#### Ways to define an interaction

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

6. An interaction with a different starting interaction id other than `start`.
   ```YAML
   interactions:
      greeting:
        messages: "The greeting message to be displayed in this interaction"
        paths: [exit]

       exit:
         messages: "Thank you"
   ```
   It is not mandatory to name starting interaction id with `start`.

7. An interaction can have multiple starting points.
  ```YAML
   interactions:
      greeting:
        messages: "The greeting message to be displayed in this interaction"
        paths: [exit]

      good_bye:
        messages: "The good bye message to be displayed in this interaction"
        paths: [exit]

       exit:
         messages: "Thank you"
   ```
   In case of multiple starting interaction ids, interaction is run by passing selected starting interaction id.

#### Troubleshooting
- Do not have response_path_map based on the response from prompts and action together in a single interaction, this could lead to ambiguity. So, atomize the interaction to either: 
  - display message,
  - take inputs from user, or
  - to perform an action item
- Prompt_type field defaults to say when not provided. So, mentioning correct prompt_type for menu, choices or taking input is necessary.
- It is recommended to key the keys in response_path_map as strings when key is space separated to maintain the consistency between different type of response.
- Any additional keys provided in the interaction file is ignored.
- Paths is mandatory for all interactions except for `exit` interaction.

#### Examples

1. basic interaction file

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

2. with timeout_yes prompt

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

3. with erb message

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

4. with timeout_select prompt

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
