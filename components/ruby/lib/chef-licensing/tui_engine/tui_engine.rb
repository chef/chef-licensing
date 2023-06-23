require_relative "tui_exceptions"
require_relative "tui_interaction"
require_relative "tui_engine_state"
require_relative "tui_prompt"
require_relative "tui_actions"
require_relative "../config"

module ChefLicensing
  class TUIEngine

    INTERACTION_FILE_FORMAT_VERSION = "1.0.0".freeze

    attr_accessor :interaction_data, :tui_interactions, :opts, :logger, :prompt_methods, :action_methods, :interaction_attributes, :traversed_interaction

    def initialize(opts = {})
      @opts = opts
      @logger = ChefLicensing::Config.logger
      @tui_interactions = {}
      @traversed_interaction = []
      initialization_of_engine(opts[:interaction_file])
      @state = ChefLicensing::TUIEngine::TUIEngineState.new(@opts)
    end

    def run_interaction(start_interaction_id = nil)
      start_interaction_id ||= @tui_interactions.keys.first
      current_interaction = @tui_interactions[start_interaction_id]

      previous_interaction = nil

      until current_interaction.nil? || current_interaction.id == :exit
        @traversed_interaction << current_interaction.id
        state.default_action(current_interaction)
        previous_interaction = current_interaction
        current_interaction = state.next_interaction_id.nil? ? nil : current_interaction.paths[state.next_interaction_id.to_sym]
      end

      # If the last interaction is not the exit interaction. Something went wrong in the flow.
      # raise the message where the flow broke.
      raise ChefLicensing::TUIEngine::IncompleteFlowException, "Something went wrong in the flow. The last interaction was #{previous_interaction&.id}." unless current_interaction&.id == :exit

      state.default_action(current_interaction)
      # remove the pastel key we used in tui engine state for styling and return the remaining parsed input
      state.input.delete(:pastel)
      state.input
    end

    def append_info_to_input(extra_info_hash)
      state.append_info_to_input(extra_info_hash)
    end

    private

    attr_accessor :state

    def initialization_of_engine(interaction_file)
      raise ChefLicensing::TUIEngine::MissingInteractionFile, "No interaction file found. Please provide a valid file path to continue." unless interaction_file

      @interaction_data = inflate_interaction_data(interaction_file)
      verify_interaction_data
      store_interaction_objects
      build_interaction_path
      logger.debug "TUI Engine initialized."
    end

    def inflate_interaction_data(interaction_file)
      require "yaml" unless defined?(YAML)
      YAML.load_file(interaction_file)
    rescue => e
      raise ChefLicensing::TUIEngine::BadInteractionFile, "Unable to load interaction file: #{interaction_file}.\n#{e.message}"
    end

    def store_interaction_objects
      unless major_version(@interaction_data[:file_format_version]) == major_version(INTERACTION_FILE_FORMAT_VERSION)
        raise ChefLicensing::TUIEngine::UnsupportedInteractionFileFormat, "Unsupported interaction file format version.\nExpected #{INTERACTION_FILE_FORMAT_VERSION} but found #{@interaction_data[:file_format_version]}."
      end

      @interaction_data["interactions"].each do |k, opts|
        opts.transform_keys!(&:to_sym)
        opts.store(:id, k.to_sym)
        @tui_interactions.store(k.to_sym, ChefLicensing::TUIEngine::TUIInteraction.new(opts))
      end
    end

    def build_interaction_path
      @interaction_data["interactions"].each do |k, opts|
        current_interaction = @tui_interactions[k.to_sym]
        opts.transform_keys!(&:to_sym)
        paths = opts[:paths] || []
        paths.each do |path|
          current_interaction.paths.store(path.to_sym, @tui_interactions[path.to_sym])
        end
      end
    end

    def verify_interaction_data
      raise ChefLicensing::TUIEngine::BadInteractionFile, "The interaction file has no data." unless @interaction_data

      raise ChefLicensing::TUIEngine::BadInteractionFile, "`file_format_version` key not found in yaml file." unless @interaction_data[:file_format_version]

      raise ChefLicensing::TUIEngine::BadInteractionFile, "`interactions` key not found in yaml file." unless @interaction_data["interactions"]

      @interaction_data["interactions"].each do |i_id, opts|
        opts.transform_keys!(&:to_sym)
        verify_interaction_purpose(i_id, opts)
        opts.each do |k, val|
          validate_interaction_attribute(i_id, k, val)
        end
      end
    end

    def verify_interaction_purpose(i_id, opts)
      # An interaction must be either action or a prompt to display messages.
      unless opts[:action] || opts[:messages]
        raise ChefLicensing::TUIEngine::BadInteractionFile, "No action or messages found for interaction #{i_id}.\nAdd either action or messages to the interaction."
      end

      # Supporting both could lead ambiguous flow in response_path_map
      if opts[:action] && opts[:messages]
        warning_message = "Both `action` and `messages` keys found in yaml file for interaction #{i_id}.\n`response_path_map` keys would be considered response from messages and not action.\nYour yaml file may not work as expected."
        warn warning_message
      end
    end

    def validate_interaction_attribute(i_id, k, val)
      if is_valid_interaction_attribute?(k)
        if k == :prompt_type && !is_valid_prompt_method?(val)
          raise ChefLicensing::TUIEngine::BadInteractionFile, "Invalid value `#{val}` for `prompt_type` key in yaml file for interaction #{i_id}."
        elsif k == :action && !is_valid_action_method?(val)
          raise ChefLicensing::TUIEngine::BadInteractionFile, "Invalid value `#{val}` for `action` key in yaml file for interaction #{i_id}."
        end
      else
        warning_message = "Invalid key `#{k}` found in yaml file for interaction #{i_id}.\nValid keys are #{@interaction_attributes.join(", ")}.\n#{k} will be ignored.\nYour yaml file may not work as expected."
        warn warning_message
      end
    end

    def is_valid_prompt_method?(val)
      @prompt_methods ||= begin
        # Find the getter methods of TUIPrompt class
        prompt_getter = ChefLicensing::TUIEngine::TUIPrompt.new.instance_variables.map { |var| var.to_s.delete("@").to_sym }

        #  Find the setter methods of TUIPrompt class
        prompt_setter = prompt_getter.map { |attr| "#{attr}=".to_sym }

        # Subtract the getter and setter of TUIPrompt class from the instance methods of TUIPrompt class
        ChefLicensing::TUIEngine::TUIPrompt.instance_methods(false) - prompt_getter - prompt_setter
      end
      @prompt_methods.include?(val.to_sym)
    end

    def is_valid_action_method?(val)
      @action_methods ||= begin
        # Find the getter methods of TUIActions class
        action_getter = ChefLicensing::TUIEngine::TUIActions.new.instance_variables.map { |var| var.to_s.delete("@").to_sym }

        #  Find the setter methods of TUIActions class
        action_setter = action_getter.map { |attr| "#{attr}=".to_sym }

        # Subtract the getter and setter of TUIActions class from the instance methods of TUIActions class
        ChefLicensing::TUIEngine::TUIActions.instance_methods(false) - action_getter - action_setter
      end
      @action_methods.include?(val.to_sym)
    end

    def is_valid_interaction_attribute?(val)
      @interaction_attributes ||= ChefLicensing::TUIEngine::TUIInteraction.new.instance_variables.map { |var| var.to_s.delete("@").to_sym }
      @interaction_attributes.include?(val.to_sym)
    end

    def major_version(version)
      Gem::Version.new(version).segments[0]
    end
  end
end
