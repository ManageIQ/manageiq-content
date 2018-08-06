#
# Description: This method checks to see if the VM has been powered off or suspended
#

module ManageIQ
  module Automate
    module Infrastructure
      module VM
        module Retirement
          module StateMachines
            class CheckPoweredOff
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                check_power_state(vm)
              end

              private

              def vm
                raise "ERROR - vm object not passed in" unless @handle.root['vm']
                @handle.root['vm']
              end

              def check_power_state(vm)
                ems = vm.ext_management_system
                if ems.nil?
                  @handle.log('info', "Skipping check powered on for VM:<#{vm(:name)}> "\
                                      "with no EMS")
                  return
                end

                power_state = vm.power_state
                @handle.log('info', "VM:<#{vm.name}> on Provider:<#{ems.name}> has Power State:<#{power_state}>")

                # If VM is powered off or suspended exit

                if %w(off suspended).include?(power_state)
                  # Bump State
                  @handle.root['ae_result'] = 'ok'
                elsif power_state == "never"
                  # If never then this VM is a template so exit the retirement state machine
                  @handle.root['ae_result'] = 'error'
                else
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

ManageIQ::Automate::Infrastructure::VM::Retirement::StateMachines::CheckPoweredOff.new.main
