module ChefLicensing
  class TUIEngine
    class TUIInteraction
      attr_accessor :id, :messages, :action, :paths
      def initialize(opts = {})
        @id = opts[:id]
        @messages = opts[:messages]
        @action = opts[:action]
        @paths = opts[:paths]
      end
    end
  end
end
