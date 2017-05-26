require 'rails/engine'

module ManageIQ
  module Content
    class Engine < ::Rails::Engine
      isolate_namespace ManageIQ::Content

      def vmdb_plugin?
        true
      end
    end
  end
end
