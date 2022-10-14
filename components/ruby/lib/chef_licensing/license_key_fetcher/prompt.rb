# Use same support libraries as license-acceptance
require "tty-prompt"
require "pastel" unless defined?(Pastel)
require "timeout" unless defined?(Timeout)
require "chef-config/windows"
require_relative "base"

module ChefLicensing
  class LicenseKeyFetcher
    # Represents fetching a license Key by interactively prompting the user,
    # and possibly querying an API to lookup a new license Key.
    class Prompt < Base

      attr_reader :logger, :output, :input, :air_gapped_env

      PASTEL = Pastel.new
      BORDER = "+---------------------------------------------+".freeze
      YES = PASTEL.green.bold("yes")
      CHECK = PASTEL.green(ChefConfig.windows? ? "√" : "✔")
      X_MARK = PASTEL.red(ChefConfig.windows? ? "x" : "×")
      CIRCLE = PASTEL.green(ChefConfig.windows? ? "O" : "◯")

      INITIAL_GREET_MSG = <<~EOM.freeze
      #{BORDER}
                  Provide Your License ID

        To access premium content and other special features,
        you will need a Chef License ID.

        If you already have one, you can enter it at the prompt
        on the following screen.

        If you need to get an evaluation or personal use license
        ID, you can get one by providing your email address.

      EOM

      LICENSE_GENERATE_GREET_MSG = <<~EOM.freeze
        #{BORDER}
                  Chef License ID Generation

        Generate Chef License ID to enjoy premium content and special features.
      EOM

      LICENSE_INPUT_GREET_MSG = <<~EOM.freeze
        Enter your License ID.

        A Chef License ID is #{LICENSE_KEY_PATTERN_DESC}.

        Enter "q" to quit without entering a Chef License ID.

      EOM

      TUI_MSGS = {
        initial_prompt_question: "Do you have a Chef License ID?",
        options: [
          "Yes, I have a Chef License ID",
          "No, I need to get a Chef License ID",
          "Exit without setting a License ID",
        ],
        license_id_msg: "License ID:",
        timeout_msg: PASTEL.red.bold("\nPrompt timed out. Exiting without a license ID set."),
        no_input_msg: PASTEL.red.bold("No License ID entered. Please try again."),
        bad_format_msg: PASTEL.red.bold("Unrecognized License ID format. Please try again."),
        invalid_license_msg: PASTEL.red.bold("License ID is not valid. Please try again."),
        validated_license_msg: PASTEL.green.bold("License validated successfully #{CHECK}"),
        general_help_msg: "If you need help, please contact #{PASTEL.green.bold("chef@progress.com")}",
        no_license_exit_msg: PASTEL.red.bold("Exiting without setting a License ID"),
        generate_success_msg: PASTEL.green.bold("License ID generated successfully #{CHECK}"),
        generate_success_help_msg: "Save your license id for future reference: ",
      }.freeze

      def initialize(cfg)
        @logger = cfg[:logger]
        @output = cfg[:output]
        @input = cfg[:input] || STDIN
        # TODO: Set @air_gap to AirGapDetectionCheck value after implementing air gap logic
        @air_gapped_env = false
      end

      def fetch
        # TODO: Set raise AirGapDetectionException("Air gap mode is not supported yet") after implementing air gap logic
        raise NotImplementedError if @air_gapped_env

        logger.debug "Prompting for license Key..."

        output.puts INITIAL_GREET_MSG

        # This first one has a timeout on it
        result = ask_if_user_has_license_id

        case result
        when /yes/i
          [ fetch_license_id_by_manual_entry ]
        when /no/i
          [ generate_license_id ]
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
          output.puts TUI_MSGS[:timeout_msg]
          return "Exit without setting a License ID"
        }

        answer = "Exit without setting a License ID"

        # TODO: Test timeout in windows
        begin
          Timeout.timeout(timeout, PromptTimeout) do
            answer = prompt.select(
              TUI_MSGS[:initial_prompt_question],
              TUI_MSGS[:options]
            )
          end
        rescue PromptTimeout
          # handled by the lambda timeout handler
          return handle_timeout.call
        end

        logger.debug("User answered: #{answer}")
        answer
      end

      def fetch_license_id_by_manual_entry
        logger.debug "Prompting for license ID..."

        output.puts LICENSE_INPUT_GREET_MSG

        logger.debug("Attempting to request interactive prompt on TTY")
        prompt = TTY::Prompt.new(track_history: false, active_color: :bold, interrupt: :exit, output: output, input: input)
        answer = prompt.ask(TUI_MSGS[:license_id_msg])

        if answer.nil? || answer.empty?
          output.puts TUI_MSGS[:no_input_msg]
          return fetch_license_id_by_manual_entry
        end

        unless (match = answer.match(/^(q|Q)|#{LICENSE_KEY_REGEX}$/))
          # TODO: this could be more graceful
          output.puts TUI_MSGS[:bad_format_msg]
          return fetch_license_id_by_manual_entry
        end

        if match[1] == "q" || match[1] == "Q"
          exit_because_user_chose_not_to_enter
        end

        unless license_valid?(match[2])
          logger.debug("License ID is not valid")
          output.puts TUI_MSGS[:invalid_license_msg]
          output.puts TUI_MSGS[:general_help_msg]
          # TODO: Output the error message from the license_validation API
          return fetch_license_id_by_manual_entry
        end

        output.puts TUI_MSGS[:validated_license_msg]
        output.puts BORDER
        match[2]
      end

      def exit_because_user_chose_not_to_enter
        output.puts TUI_MSGS[:no_license_exit_msg]
        # Inspec::UI.new.exit
        # TODO: consider special exit code here
        exit
      end

      def generate_license_id
        logger.debug "Generating a new license ID..."
        output.puts LICENSE_GENERATE_GREET_MSG

        # TODO: This is dependent on implementation of `Generation TUI ticket` ticket
        # This implements the TUI for generating a new license ID of different types
        # This should return a valid license ID by possibly querying an API
        license_id = "1234567890"
        puts TUI_MSGS[:generate_success_msg]
        puts TUI_MSGS[:generate_success_help_msg] + PASTEL.green.bold(license_id)
        license_id
      end

      def license_valid?(license_id)
        # TODO: This is dependent on implementation of `Validate License Key with License Server` ticket
        # begin
        #   validity = call_the_license_validation_api(license_id)
        # rescue => exception
        #   output.puts PASTEL.red.bold("Error validating license ID: #{exception}")
        # end
        true
      end

      class PromptTimeout < Timeout::Error; end
    end
  end
end
