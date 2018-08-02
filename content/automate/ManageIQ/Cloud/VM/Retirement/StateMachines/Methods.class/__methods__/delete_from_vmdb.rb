#
# Description: This method removes the VM from the VMDB database
#
module ManageIQ
  module Automate
    module Cloud
      module VM
        module Retirement
          module StateMachines
            module Methods
              class DeleteFromVmdb
                def initialize(handle = $evm)
                  @handle = handle
                end

                def main
                  vm = @handle.root['vm']

                  if vm && @handle.get_state_var('vm_removed_from_provider')
                    @handle.log('info', "Removing VM <#{vm.name}> from VMDB")
                    vm.remove_from_vmdb
                    @handle.root['vm'] = nil
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Cloud::VM::Retirement::StateMachines::Methods::DeleteFromVmdb.new.main
