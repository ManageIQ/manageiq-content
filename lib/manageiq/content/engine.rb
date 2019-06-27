require 'rails/engine'

module ManageIQ
  module Content
    class Engine < ::Rails::Engine
      isolate_namespace ManageIQ::Content

      def self.vmdb_plugin?
        true
      end

      def self.plugin_name
        _('Content')
      end
    end
  end
end
