#
# Description: This method checks to see if the VM has been removed from the provider
#

module ManageIQ
  module Automate
    module Infrastructure
      module VM
        module Retirement
          module StateMachines
            class CheckRemovedFromProvider
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                check_removed_from_provider(vm)
              end

              private

              def vm
                raise "ERROR - vm object not passed in" unless @handle.root['vm']
                @handle.root['vm']
              end

              def check_removed_from_provider(vm)
                @handle.root['ae_result'] = 'ok'
                if vm.ext_management_system && @handle.get_state_var('vm_removed_from_provider')
                  if vm.respond_to?(:exists_on_provider?)
                    vm.exists_on_provider? ? vm.refresh : return
                  else
                    vm.refresh
                  end
                  @handle.root['ae_result'] = 'retry'
                  @handle.root['ae_retry_interval'] = '60.seconds'
                end
              end
            end
          end
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  ManageIQ::Automate::Infrastructure::VM::Retirement::StateMachines::CheckRemovedFromProvider.new.main
end
