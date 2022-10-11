module ChefLicensing
  class TUIEngine
    class TUIPrompt
      def select(messages)
        header = @all_messages[messages[0].to_sym]

        choices_list = []
        choices_map = {}

        # TODO: Improve the comments.

        # Why are we doing this?
        # @all_messages is the hash of all key-values from the messages.yaml file.
        # messages has the keys of the text we want to display to the user.
        # we want to display the values to the keys given in messages; hence choices_list
        # but we want to return the key of the text the user selects; hence choices_map
        messages[1].map do |message|
          choices_list.push(@all_messages[message.to_sym])
          choices_map[message.to_sym] = @all_messages[message.to_sym]
        end

        response = @tty_prompt.select(header, choices_list)

        # returns the key of the text the user selected
        # this response key is mapped to the next interaction id in the response_path_map
        choices_map.key(response)
      end
    end
  end
end