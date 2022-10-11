module ChefLicensing
  class TUIEngine
    class TUIPrompt
      def enum_select(messages)
        @tty_prompt.enum_select(messages[0], messages[1])
      end
    end
  end
end