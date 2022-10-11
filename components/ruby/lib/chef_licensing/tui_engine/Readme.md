### TUI Engine [Draft Version]

TUI Engine helps to build the flow of a text user interface.

It separates out the high level flow from the core implementation. The high level flow could be defined in a yaml file which contains a collection of interactions which has the text to be displayed, any action associated with it, and the path to next interactions. 

Type of interactions could be:
1. Display -> followed by one path
2. Take input -> followed by one path
3. Yes or no -> possible actions 2
4. Menu/Options -> possible actions n
5. Action - no display only operation