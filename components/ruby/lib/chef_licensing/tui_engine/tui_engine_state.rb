module ChefLicensing
  class TUIEngine
    class TUIEngineState < Hash
      attr_accessor :next_interaction_id

      # TODO: Populate the yaml file with correct actions
      # Implement the actions here
      def welcome_function
        puts "Welcome to the license engine"
        @next_interaction_id = "ask_if_user_has_license_id"
      end

      def question_about_license_id
        puts "Do you have license id?"
        @next_interaction_id = "ask_for_license_id"
      end

      def accept_license_id_from_user
        puts "Please enter your license id"
      end

      def license_generator
        puts "Please enter your license id"
      end

      def exit_function
        puts "Exiting"
      end
    end
  end
end