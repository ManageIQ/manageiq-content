#
# Description: This method stops the Amazon Instance
# If the Instance is not on a EBS store we can skip stopping the instance
#
module ManageIQ
  module Automate
    module Cloud
      module VM
        module Retirement
          module StateMachines
            module Methods
              class AmazonPreRetirement
                def initialize(handle = $evm)
                  @handle = handle
                end

                def main
                  vm = @handle.root['vm']
                  ems = vm.ext_management_system if vm
                  if vm.nil? || ems.nil?
                    @handle.log('info', "Skipping Amazon pre retirement for Instance:<"\
                                        "#{vm.try(:name)}> on EMS:<#{ems.try(:name)}> "\
                                        "with instance store type <#{vm.try(:hardware).try(:root_device_type)}>")
                  else
                    power_state = vm.power_state
                    if power_state == "on"
                      if vm.hardware.try(:root_device_type).blank?
                        @handle.log('error', "Aborting Amazon pre retirement, empty root_device_type. "\
                                             "Instance <#{vm.name}> may have been provisioned externally.")
                        raise 'Aborting Amazon pre retirement'
                      elsif vm.hardware.try(:root_device_type) == "ebs"
                        @handle.log('info', "Stopping EBS Amazon Instance <#{vm.name}> in EMS <#{ems.name}>")
                        vm.stop
                      else
                        @handle.log('info', "Skipping stopping of non EBS Amazon Instance <#{vm.name}> in EMS <#{ems.name}>"\
                                            " with instance store type <#{vm.hardware.root_device_type}>")
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
end

ManageIQ::Automate::Cloud::VM::Retirement::StateMachines::Methods::AmazonPreRetirement.new.main
