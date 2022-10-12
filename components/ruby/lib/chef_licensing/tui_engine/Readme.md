### TUI Engine [Draft Version]

TUI Engine helps to build the flow of a text user interface.

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
# Yaml file empty -> give good exception
# Wrong keys in yaml file
# Missing keys in yaml file
# Extra keys in yaml file
# Wrong combinations of keys in yaml file (example: action and prompt cannot be toghether)
# Validation of value used in yaml file
# Raise exception when prompt_type is not supported
# All exception message must be logger debug
# Messages for customers should be generic