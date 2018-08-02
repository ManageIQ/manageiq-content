#
# Description: This method checks to see if the VM has been removed from the provider
#
module ManageIQ
  module Automate
    module Cloud
      module VM
        module Retirement
          module StateMachines
            module Methods
              class CheckRemovedFromProvider
                def initialize(handle = $evm)
                  @handle = handle
                end

                def main
                  vm = @handle.root['vm']
                  @handle.root['ae_result'] = 'ok'

                  if vm && @handle.get_state_var('vm_removed_from_provider')
                    if vm.ext_management_system
                      vm.refresh
                      @handle.root['ae_result']         = 'retry'
                      @handle.root['ae_retry_interval'] = '1.minute'
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
end

ManageIQ::Automate::Cloud::VM::Retirement::StateMachines::Methods::CheckRemovedFromProvider.new.main
