module ChefLicensing
  class TUIEngine
    class TUIPrompt
      def yes(message)
        msg = @all_messages[message[0].to_sym]
        @tty_prompt.yes?(msg, default: true)
      end
    end
  end
end