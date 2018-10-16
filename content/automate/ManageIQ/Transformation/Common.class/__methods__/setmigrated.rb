module ManageIQ
  module Automate
    module Transformation
      module Common
        class SetMigrated
          def initialize(handle = $evm)
            @handle = handle
            @task = ManageIQ::Automate::Transformation::Common::Utils.task(@handle)
          end

          def main
            @task.mark_vm_migrated
          rescue => e
            @handle.set_state_var(:ae_state_progress, 'message' => e.message)
            raise
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Transformation::Common::SetMigrated.new.main
