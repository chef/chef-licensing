module ChefLicensing
  class TUIEngine
    class TUIInteraction
      attr_accessor :id, :messages, :action, :paths, :prompt_type, :response_path_map
      def initialize(opts = {})
        @id = opts[:id]
        @messages = opts[:messages]
        @action = opts[:action]
        @prompt_type = opts[:prompt_type] || "say"
        @response_path_map = opts[:response_path_map]
        @paths = {}
      end
    end
  end
end
