module ManageIQ
  module Content
    class Engine < ::Rails::Engine
      isolate_namespace ManageIQ::Content

      config.autoload_paths << root.join('lib').to_s

      def self.vmdb_plugin?
        true
      end

      def self.plugin_name
        _('Content')
      end
    end
  end
end
