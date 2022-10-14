## TUI Engine

TUI Engine helps to build a text user interface considering each step involved in the text user interface as interaction.

### Syntax

A basic interaction is described as below:
```YAML
interactions:
  start:
    messages: "The message to be displayed in this interaction"
    prompt_type: "say"
    paths: []
    description: "Some description about this interaction"
```

The different keys in an interaction file are:

1. `interactions`

   `interactions` key is the parent key in an interaction file. Every interaction must be defined under this key.

2. `<interaction_id>`

   `<interaction_id>` key is the identifier of any interaction, which defines a particular interaction.

   Evert interaction file must have an interaction with the interaction id as `start`.
   The flow of interaction starts from the `start` interaction.

3. `messages`

   `messages` key is the key of an interaction which contains the texts to be displayed to the user.

   `messages` can receive texts as an array or a string.

   For general purpose display, texts can be provided as string. 

   - Example: `messages: "This is the text to be displayed"`

   Or it could be even provided as an array, and only the message at zeroth index would be picked.

   - Example: `messages: ["This is the text to be displayed"]`

   However, we need to provided the texts as an array or arrays when the provided text is to be displayed as menu. The format to be followed is as: `[header, [choices]]`

   - Example: `messages: ["The header of the menu", ["Option 1", "Option 2"]]`
   
4. `prompt_type`
   
   `prompt_type` key is another key of an interaction which accepts value representing different types of prompt. Currently, the supported prompt types are:

   - `say`: displays the message, returns nil
   - `yes`: displays the message, asks for input from user. Returns true when input is given as `yes` or `y`, and false on input of `no` or `n`.
   - `ok`: displays the message in green color, returns the message.
   - `warn` displays the message in yellow/orange color, returns the message.
   - `error`: displayes the message in red color, returns the message.
   - `select`: displays the menu header and choices, returns the selected choice.
   - `enum_select`: displays the menu header and choices, returns the selected choice.
   - `ask`: displays the message, returns the input value.

   This key is an optional and defaults to prompt_type of `say`.

5. `paths`

   `paths` key is another key of an interaction which accepts an array of interaction id to which it could be follow after the current responsibility of the interaction is complete.

6. `action`

   `action`  key is another key of an interaction which accepts a method name. The methods are to be defined in `TUIActions` class.

7. `response_path_map`

   `response_path_map` key is another key of an interaction which contains a mapping of `<response>: <interaction id>`

   The response could be from either prompt display or from action, but not both.

8. `description`

   `description` is an optional field of an interaction which is used to describe interaction for readability of the interaction file.


The different ways how we can define an interaction is shown below.

1. TUI with one interaction.
   ```YAML
   interactions:
      start:
        messages: "The message to be displayed in this interaction"
        prompt_type: "say"
        paths: []
        description: "Some description about this interaction"
   ```
   Here, `start` is the interaction id. prompt



It separates out the high level flow from the core implementation. The high level flow could be defined in a yaml file which contains a collection of interactions which has the text to be displayed, any action associated with it, and the path to next interactions. 

Type of interactions could be:
1. Display -> followed by one path
2. Take input -> followed by one path
3. Yes or no -> possible actions 2
4. Menu/Options -> possible actions n
5. Action - no display only operation


Rules:
An interaction can be either a prompt type or action type. But cannot be both. Explain why? Hint: Response_path_mapping
It cannot have two different response path map at the same time.

# Define the must have keys
# Yaml file empty -> give good exception - done
# Wrong keys in yaml file
# Missing keys in yaml file
# Extra keys in yaml file
# Wrong combinations of keys in yaml file (example: action and prompt cannot be toghether)
# Validation of value used in yaml file
# Raise exception when prompt_type is not supported
# All exception message must be logger debug
# Messages for customers should be generic

In yaml file:
paths is optional and defaults to []
prompt_type can be optional and defaults to say
description is not used in the tui engine and is only for reference to understand interaction in the yaml

Keep response_path key to be string for consistency