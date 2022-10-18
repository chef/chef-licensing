require_relative "tui_exceptions"
require_relative "tui_interaction"
require_relative "tui_engine_state"

module ChefLicensing
  class TUIEngine

    attr_accessor :interaction_data, :tui_interactions, :opts

    def initialize(opts = {})
      @opts = opts
      @tui_interactions = {}
      initialization_of_engine(opts[:interaction_file])
    end

    def run_interaction
      current_interaction = @tui_interactions[:start]
      state = ChefLicensing::TUIEngine::TUIEngineState.new(@opts)

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
      state.processed_input
    end

    private

    def initialization_of_engine(interaction_file)
      interaction_file ||= File.join(File.dirname(__FILE__), "default_interactions.yaml")
      @interaction_data = inflate_interaction_data(interaction_file)
      verify_interaction_data
      store_interaction_objects
      build_interaction_path
    end

    def inflate_interaction_data(interaction_file)
      require "yaml" unless defined?(YAML)
      YAML.load_file(interaction_file)
    rescue => e
      raise ChefLicensing::TUIEngine::YAMLException, "Unable to load interaction file. #{e.message}"
    end

    def store_interaction_objects
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
      raise ChefLicensing::TUIEngine::YAMLException, "No interactions found in yaml file." unless @interaction_data

      raise ChefLicensing::TUIEngine::YAMLException, "`interactions` key not found in yaml file." unless @interaction_data["interactions"]

      @interaction_data["interactions"].each do |i_id, opts|
        if opts[:action] && opts[:messages]
          warn "Both `action` and `messages` keys found in yaml file for interaction #{i_id}."
          warn "`response_path_map` keys would be considered response from messages and not action."
        end

        opts.transform_keys!(&:to_sym)

        opts.each do |k, val|
          unless %i{action messages paths prompt_type response_path_map description}.include?(k)
            warn "Invalid key `#{k}` found in yaml file for interaction #{i_id}."
            warn "Valid keys are `action`, `messages`, `paths`, `prompt_type`, `response_path_map` and `description`."
            warn "#{k} will be ignored.\nYour yaml file may not work as expected."
          end

          # check prompt_type value is valid
          if k == :prompt_type
            unless %w{yes say ask ok warn error select enum_select}.include?(val)
              raise ChefLicensing::TUIEngine::YAMLException, "Invalid value `#{val}` for `prompt_type` key in yaml file for interaction #{i_id}."
            end
          end
        end
      end
    end
  end
end
