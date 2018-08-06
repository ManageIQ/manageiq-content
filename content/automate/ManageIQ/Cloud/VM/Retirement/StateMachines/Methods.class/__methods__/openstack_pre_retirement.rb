#
# Description: This method suspends the Openstack Instance
#
module ManageIQ
  module Automate
    module Cloud
      module VM
        module Retirement
          module StateMachines
            module Methods
              class OpenstackPreRetirement
                def initialize(handle = $evm)
                  @handle = handle
                end

                def main
                  vm = @handle.root['vm']
                  unless vm.nil? || vm.attributes['power_state'] == 'off'
                    ems = vm.ext_management_system
                    @handle.log('info', "Suspending Openstack Instance <#{vm.name}> in EMS <#{ems.try(:name)}")
                    vm.suspend if ems
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

ManageIQ::Automate::Cloud::VM::Retirement::StateMachines::Methods::OpenstackPreRetirement.new.main
