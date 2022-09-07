# Use same support libraries as license-acceptance
require "tty-prompt"
require "pastel"
require "timeout"
require "chef-config/windows"
require_relative "base"

module ChefLicensing
  class LicenseKeyFetcher
    # Represents fetching a license Key by interactively prompting the user,
    # and possibly querying an API to lookup a new license Key.
    class Prompt < Base

      attr_reader :logger, :output, :input

      PASTEL = Pastel.new
      BORDER = "+---------------------------------------------+".freeze
      YES = PASTEL.green.bold("yes")
      CHECK = PASTEL.green(ChefConfig.windows? ? "√" : "✔")
      X_MARK = PASTEL.red(ChefConfig.windows? ? "x" : "×")
      CIRCLE = PASTEL.green(ChefConfig.windows? ? "O" : "◯")

      def initialize(cfg)
        @logger = cfg[:logger]
        @output = cfg[:output]
        @input = cfg[:input] || STDIN
      end

      def fetch
        # TODO: Make it gracefully exit if air gap is enabled
        raise "AIR_GAP is enabled" if air_gap?

        logger.debug "Prompting for license Key..."

        output.puts <<~EOM
        #{BORDER}
                    Provide Your License ID

          To access premium content and other special features,
          you will need a Chef License ID.

          If you already have one, you can enter it at the prompt
          on the following screen.

          If you need to get an evaluation or personal use license
          ID, you can get one by providing your email address.

        EOM

        # This first one has a timeout on it
        result = ask_if_user_has_license_id

        case result
        when /yes/i
          fetch_license_id_by_manual_entry
        when /no/i
          generate_license_id
        when /exit/i
          exit_because_user_chose_not_to_enter
        end
      end

      private

      def ask_if_user_has_license_id
        logger.debug("Asking if user has a license ID")
        prompt = TTY::Prompt.new(track_history: false, active_color: :bold, interrupt: :exit, output: output, input: input)
        timeout = ENV["CI_TELEMETRY_PROMPT_TIMEOUT"].nil? ? 60 : ENV["CI_TELEMETRY_PROMPT_TIMEOUT"].to_i
        handle_timeout = ->() {
          logger.debug("User did not respond to prompt in #{timeout} seconds")
          prompt.unsubscribe(prompt.reader)
          output.puts PASTEL.red.bold("\nPrompt timed out. Exiting without a license ID set.")
          return "Exit without setting a License ID"
        }

        answer = "Exit without setting a License ID"

        # TODO: Test timeout in windows
        begin
          Timeout.timeout(timeout, PromptTimeout) do
            answer = prompt.select(
              "Do you have a Chef License ID?",
              [
                "Yes, I have a Chef License ID",
                "No, I need to get a Chef License ID",
                "Exit without setting a License ID",
              ]
            )
          end
        rescue Timeout::Error
          # handled by the lambda timeout handler
          return handle_timeout.call
        end

        logger.debug("User answered: #{answer}")
        answer
      end

      def fetch_license_id_by_manual_entry
        logger.debug "Prompting for license ID..."

        output.puts <<~EOM
          Enter your License ID.

          A Chef License ID is #{LICENSE_KEY_PATTERN_DESC}.

          Enter "q" to quit without entering a Chef License ID.

        EOM

        logger.debug("Attempting to request interactive prompt on TTY")
        prompt = TTY::Prompt.new(track_history: false, active_color: :bold, interrupt: :exit, output: output, input: input)
        answer = prompt.ask("License ID:")

        unless (match = answer.match(/^(q|Q)|#{LICENSE_KEY_REGEX}$/))
          # TODO: this could be more graceful
          output.puts PASTEL.red.bold("Unrecognized License ID format #{answer}")
          return fetch_license_id_by_manual_entry
        end

        if match[1] == "q" || match[1] == "Q"
          exit_because_user_chose_not_to_enter
        end

        unless license_valid?(match[2])
          logger.debug("License ID is not valid")
          output.puts PASTEL.red.bold("License ID is not valid")
          output.puts "If you need help, please contact #{PASTEL.green.bold("chef@progress.com")}"
          # TODO: Output the error message from the license_validation API
          return fetch_license_id_by_manual_entry
        end

        output.puts PASTEL.green.bold("License validated successfully #{CHECK}")
        output.puts BORDER
        match[2]
      end

      def exit_because_user_chose_not_to_enter
        output.puts PASTEL.red.bold("Exiting without setting a License ID")

        # Inspec::UI.new.exit
        # TODO: consider special exit code here
        # TODO: Check if we should set a license ID to nil to not prompt again
        exit
      end

      def generate_license_id
        logger.debug "Generating a new license ID..."
        output.puts <<~EOM
          #{BORDER}
                    Chef License ID Generation

          Generate Chef License ID to enjoy premium content and special features.
        EOM

        # TODO: This is dependent on implementation of `Generation TUI ticket` ticket
        # This implements the TUI for generating a new license ID of different types
        # This should return a valid license ID by possibly querying an API
        license_id = "1234567890"
        puts PASTEL.green.bold("Successfully generated a new license ID #{CHECK}")
        puts "Save your license id #{PASTEL.green.bold(license_id)} for future reference."
        license_id
      end

      def air_gap?
        # TODO: Implement the below logic
        # return true: if env variable is set to enable air gap or
        #              if local setting is set to enable air gap or
        #              if unable to ping public Chef server
        false
      end

      def license_valid?(license_id)
        # TODO: This is dependent on implementation of `Validate License Key with License Server` ticket
        true
      end

      class PromptTimeout < Timeout::Error; end
    end
  end
end
