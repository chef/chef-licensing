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

3. `messages`:  `messages` key is the key of an interaction which contains the texts to be displayed to the user. `messages` can receive texts as an array or a string.

   For general purpose display, texts can be provided as string. 

   - Example: `messages: "This is the text to be displayed"`

   Or it could be even provided as an array, and only the message at zeroth index would be picked.

   - Example: `messages: ["This is the text to be displayed"]`

   However, we need to provided the texts as an array or arrays when the provided text is to be displayed as menu. The format to be followed is as: `[header, [choices]]`

   - Example: `messages: ["The header of the menu", ["Option 1", "Option 2"]]`
   
4. `prompt_type`: `prompt_type` key is another key of an interaction which accepts value representing different types of prompt. Currently, the supported prompt types are:

   - `say`: displays the message, returns nil
   - `yes`: displays the message, asks for input from user. Returns true when input is given as `yes` or `y`, and false on input of `no` or `n`.
   - `ok`: displays the message in green color, returns the message.
   - `warn` displays the message in yellow/orange color, returns the message.
   - `error`: displayes the message in red color, returns the message.
   - `select`: displays the menu header and choices, returns the selected choice.
   - `enum_select`: displays the menu header and choices, returns the selected choice.
   - `ask`: displays the message, returns the input value.

   This key is an optional and defaults to prompt_type of `say`.

5. `paths`: `paths` key is another key of an interaction which accepts an array of interaction id to which it could be follow, after the current responsibility of the interaction is complete. Every interaction must have a path except for the `exit` interaction.

6. `action`: `action`  key is another key of an interaction which accepts a method name. The methods are to be defined in `TUIActions` class.

7. `response_path_map`: `response_path_map` key is another key of an interaction which contains a mapping of `<response>: <interaction id>`

   The response could be from either prompt display or from action, but not both.

8. `description`: `description` is an optional field of an interaction which is used to describe interaction for readability of the interaction file.

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

## Example
```YAML
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
