#
# Description: This method stops a cloud Instance
#
module ManageIQ
  module Automate
    module Cloud
      module VM
        module Retirement
          module StateMachines
            module Methods
              class PreRetirement
                def initialize(handle = $evm)
                  @handle = handle
                end

                def main
                  vm = @handle.root['vm']
                  if vm && vm.power_state == 'on'
                    ems = vm.ext_management_system
                    if ems
                      @handle.log('info', "Stopping Instance <#{vm.name}> in EMS <#{ems.name}>")
                      vm.stop
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

ManageIQ::Automate::Cloud::VM::Retirement::StateMachines::Methods::PreRetirement.new.main
