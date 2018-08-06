#
# Description: This method checks to see if the VM has been deleted from the provider
#
module ManageIQ
  module Automate
    module Cloud
      module VM
        module Retirement
          module StateMachines
            module Methods
              class CheckDeletedFromProvider
                def initialize(handle = $evm)
                  @handle = handle
                end

                def main
                  vm = @handle.root['vm']
                  @handle.root['ae_result'] = 'ok'

                  if vm && @handle.get_state_var('vm_deleted_from_provider')
                    if vm.ext_management_system
                      @handle.root['ae_result']         = 'retry'
                      @handle.root['ae_retry_interval'] = '15.seconds'
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

ManageIQ::Automate::Cloud::VM::Retirement::StateMachines::Methods::CheckDeletedFromProvider.new.main
