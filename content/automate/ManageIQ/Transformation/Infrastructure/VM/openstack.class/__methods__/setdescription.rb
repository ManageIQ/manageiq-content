module ManageIQ
  module Automate
    module Transformation
      module Infrastructure
        module VM
          module OpenStack
            class SetDescription
              def initialize(handle = $evm)
                @handle = handle
                @destination_vm = ManageIQ::Transformation::Common::Utils.destination_vm(@handle)
              end

              def main
                description = "Migrated by Cloudforms on #{Time.now.utc}."
                ManageIQ::Automate::Transformation::Infrastructure::VM::OpenStack::Utils.vm_set_description(destination_vm, description)
              rescue => e
                @handle.set_state_var(:ae_state_progress, 'message' => e.message)
                raise
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Transformation::Infrastructure::VM::OpenStack::SetDescription.new.main
