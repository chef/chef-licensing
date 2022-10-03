### TUI Engine

TUI Engine helps to build the flow of a text user interface.

It separates out the high level flow from the core implementation. The high level flow could be defined in a yaml file which contains a collection of interactions which has the text to be displayed, any action associated with it, and the path to next interactions. 

Example of a yaml file:
```yaml
nodes:
  license_id_welcome_note:
    messages: ["hello"]
    action_item: welcome_function
    paths: [ask_if_user_has_license_id]
  ask_if_user_has_license_id:
    messages: ["Do you have a License ID?"]
    action_item: question_about_license_id
    paths: [ask_for_license_id, ]
  ask_for_license_id:
    messages: ["Please input your License ID: "]
    action_item: accept_license_id_from_user
    paths: []
  ask_for_license_generation:
    messages: ["Which license id do you want generate?"]
    action_item: license_generator
    paths: []
  exit_license_tui:
    messages: ["Thank you!"]
    action_item: exit_function
    paths: []
```
The implementation of the action is to be defined in `tui_engine_state`.
Example:
```ruby
def welcome_function(interaction)
  puts interaction.messages
end
```

The tui_engine then can be used as follows:
```ruby
# require the tui_engine file

# tui_engine = ChefLicensing::TUIEngine.new(
#   {
#     :yaml_file =>  <path of the yaml file>,
#   }
# )

# If yaml_file is not provided as the opts, it picks the default.yaml file
tui_engine = ChefLicensing::TUIEngine.new

data = tui_engine.run_interaction

# data would contain the important inputs/information received/processed during the flow.
```