require_relative "tui_exceptions"
require_relative "tui_interaction"
require_relative "tui_engine_state"
require_relative "tui_prompt"
require_relative "tui_actions"
require_relative "../config"

module ChefLicensing
  class TUIEngine

    INTERACTION_FILE_FORMAT_VERSION = "1.0.0".freeze

    attr_accessor :interaction_data, :tui_interactions, :opts, :logger, :prompt_methods, :action_methods, :interaction_attributes

    def initialize(opts = {})
      @opts = opts
      @logger = ChefLicensing::Config.logger
      @tui_interactions = {}
      initialization_of_engine(opts[:interaction_file])
      @state = ChefLicensing::TUIEngine::TUIEngineState.new(@opts)
    end

    def run_interaction(start_interaction = nil)
      start_interaction_id = start_interaction || @tui_interactions.keys.first
      current_interaction = @tui_interactions[start_interaction_id]

      until current_interaction.nil? || current_interaction.id == :exit
        state.default_action(current_interaction)

        if state.next_interaction_id.nil?
          current_interaction = nil
        else
          current_interaction = current_interaction.paths[state.next_interaction_id.to_sym]
        end
      end

      # If the last interaction is not the exit interaction. Something went wrong in the flow.
      raise ChefLicensing::TUIEngine::IncompleteFlowException, "Something went wrong in the flow." if current_interaction.nil? || current_interaction.id != :exit

      state.default_action(current_interaction)
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

        # An interaction must be either action or a prompt to display messages.
        if opts[:action].nil? && opts[:messages].nil?
          raise ChefLicensing::TUIEngine::BadInteractionFile, "No action or messages found for interaction #{i_id}.\nAdd either action or messages to the interaction."
        end

        # Supporting both could lead ambiguous flow in response_path_map
        if opts[:action] && opts[:messages]
          warn "Both `action` and `messages` keys found in yaml file for interaction #{i_id}."
          warn "`response_path_map` keys would be considered response from messages and not action."
        end

        opts.each do |k, val|
          # check for invalid keys in an interaction
          unless is_valid_interaction_attribute?(k)
            warn "Invalid key `#{k}` found in yaml file for interaction #{i_id}."
            warn "Valid keys are #{@interaction_attributes.join(", ")}."
            warn "#{k} will be ignored.\nYour yaml file may not work as expected."
          end

          # check if tui_engine supports the prompt_type
          if k == :prompt_type && !is_valid_prompt_method?(val)
            raise ChefLicensing::TUIEngine::BadInteractionFile, "Invalid value `#{val}` for `prompt_type` key in yaml file for interaction #{i_id}."
          end

          # check if tui_engine supports the action
          if k == :action && !is_valid_action_method?(val)
            raise ChefLicensing::TUIEngine::BadInteractionFile, "Invalid value `#{val}` for `action` key in yaml file for interaction #{i_id}."
          end
        end
      end
    end

    def is_valid_prompt_method?(val)
      return @prompt_methods.include?(val.to_sym) if @prompt_methods

      # Find the getter methods of TUIPrompt class
      prompt_getter = ChefLicensing::TUIEngine::TUIPrompt.new.instance_variables.map { |var| var.to_s.delete("@").to_sym }

      #  Find the setter methods of TUIPrompt class
      prompt_setter = prompt_getter.map { |attr| "#{attr}=".to_sym }

      # Subtract the getter and setter of TUIPrompt class from the instance methods of TUIPrompt class
      @prompt_methods = ChefLicensing::TUIEngine::TUIPrompt.instance_methods(false) - prompt_getter - prompt_setter

      @prompt_methods.include?(val.to_sym)
    end

    def is_valid_action_method?(val)
      return @action_methods.include?(val.to_sym) if @action_methods

      # Find the getter methods of TUIActions class
      action_getter = ChefLicensing::TUIEngine::TUIActions.new.instance_variables.map { |var| var.to_s.delete("@").to_sym }

      #  Find the setter methods of TUIActions class
      action_setter = action_getter.map { |attr| "#{attr}=".to_sym }

      # Subtract the getter and setter of TUIActions class from the instance methods of TUIActions class
      @action_methods = ChefLicensing::TUIEngine::TUIActions.instance_methods(false) - action_getter - action_setter

      @action_methods.include?(val.to_sym)
    end

    def is_valid_interaction_attribute?(val)
      return @interaction_attributes.include?(val.to_sym) if @interaction_attributes

      @interaction_attributes = ChefLicensing::TUIEngine::TUIInteraction.new.instance_variables.map { |var| var.to_s.delete("@").to_sym }

      @interaction_attributes.include?(val.to_sym)
    end

    def major_version(version)
      Gem::Version.new(version).segments[0]
    end
  end
end
