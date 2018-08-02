# / Infra / VM / Retirement / StateMachines / PreRetirement

#
# Description: This method powers-off the VM on the provider
#

module ManageIQ
  module Automate
    module Infrastructure
      module VM
        module Retirement
          module StateMachines
            class PreRetirement
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                # Get vm from root object
                vm = @handle.root['vm']
                check_power_state(vm)
              end

              def check_power_state(vm)
                unless vm.nil? || vm.attributes['power_state'] == 'off'
                  ems = vm.ext_management_system
                  @handle.log('info', "Powering Off VM <#{vm.name}> in provider <#{ems.try(:name)}>")
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

ManageIQ::Automate::Infrastructure::VM::Retirement::StateMachines::PreRetirement.new.main
