module ManageIQ
  module Automate
    module Transformation
      module Infrastructure
        module VM
          module Common
            class CheckVmInInventory
              def initialize(handle = $evm)
                @handle = handle
                @task = ManageIQ::Automate::Transformation::Common::Utils.task(@handle)
                @source_vm = ManageIQ::Automate::Transformation::Common::Utils.source_vm(@handle)
              end

              def main
                destination_vm = @handle.vmdb(:vm).find_by(:name => @source_vm.name, :ems_id => @task.destination_ems.id)
                if destination_vm.nil?
                  @handle.root['ae_result'] = 'retry'
                  @handle.root['ae_retry_interval'] = '15.seconds'
                else
                  @task.set_option(:destination_vm_id, destination_vm.id)
                end
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

ManageIQ::Automate::Transformation::Infrastructure::VM::Common::CheckVmInInventory.new.main
