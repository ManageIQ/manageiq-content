module ManageIQ
  module Automate
    module Transformation
      module Infrastructure
        module VM
          module RedHat
            class SetDescription
              def initialize(handle = $evm)
                @handle = handle
                @task = ManageIQ::Automate::Transformation::Common::Utils.task(@handle)
                @destination_vm = ManageIQ::Automate::Transformation::Common::Utils.destination_vm(@handle)
              end

              def main
                return unless @destination_vm.vendor == 'redhat'
                description = "Migrated by Cloudforms on #{Time.now.utc}."
                ManageIQ::Automate::Transformation::Infrastructure::VM::RedHat::Utils.new(@task.destination_ems).vm_set_description(@destination_vm, description)
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

ManageIQ::Automate::Transformation::Infrastructure::VM::RedHat::SetDescription.new.main
