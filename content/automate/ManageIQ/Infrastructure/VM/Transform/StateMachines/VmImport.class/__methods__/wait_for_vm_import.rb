#
# Description: This method checks if the VM has been successfully imported
#

module ManageIQ
  module Automate
    module Infrastructure
      module VM
        module Transform
          module StateMachines
            class WaitForVmImport
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                vm = imported_vm
                if vm
                  status = vm.custom_get(:import_status)
                  case status
                  when 'success'
                    @handle.set_state_var('imported_vm_id', vm.id)
                    @handle.root['ae_result'] = 'ok'
                  when 'failure'
                    @handle.root['ae_result'] = 'error'
                  else
                    set_retry
                  end
                else
                  set_retry
                end
              end

              def set_retry
                @handle.root['ae_result'] = 'retry'
                @handle.root['ae_retry_interval'] = @handle.inputs['retry_interval'] || 3.minutes
              end

              def imported_vm
                ems_ref = @handle.get_state_var('new_ems_ref')
                @handle.vmdb(:Vm).find_by(:ems_ref => ems_ref)
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Infrastructure::VM::Transform::StateMachines::WaitForVmImport.new.main
