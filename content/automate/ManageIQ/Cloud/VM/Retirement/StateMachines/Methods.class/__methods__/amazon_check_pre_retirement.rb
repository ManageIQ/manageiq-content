#
# Description: This method checks to see if the amazon instance has been powered off
# if the instance is on a instance store we cannot stop it
#
module ManageIQ
  module Automate
    module Cloud
      module VM
        module Retirement
          module StateMachines
            module Methods
              class AmazonCheckPreRetirement
                def initialize(handle = $evm)
                  @handle = handle
                end

                def main
                  # Get vm from root object
                  vm = @handle.root['vm']
                  ems = vm.ext_management_system if vm

                  if vm.nil? || ems.nil?
                    @handle.log('info', "Skipping check pre retirement for Instance:<#{vm.try(:name)}> on EMS:<#{ems.try(:name)}>")
                  else
                    power_state = vm.power_state
                    @handle.log('info', "Instance:<#{vm.name}> on EMS:<#{ems.name}> has Power State:<#{power_state}>")
                    # If VM is powered off, suspended, terminated, unknown or this instance is running on an instance store exit
                    if %w(off suspended terminated unknown).include?(power_state) || vm.hardware.root_device_type == "instance-store"
                      # Bump State
                      @handle.root['ae_result'] = 'ok'
                    elsif power_state == "never"
                      # If never then this VM is a template so exit the retirement state machine
                      @handle.root['ae_result'] = 'error'
                      raise 'Trying to power off a template'
                    else
                      vm.refresh
                      @handle.root['ae_result']         = 'retry'
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
  end
end

ManageIQ::Automate::Cloud::VM::Retirement::StateMachines::Methods::AmazonCheckPreRetirement.new.main
