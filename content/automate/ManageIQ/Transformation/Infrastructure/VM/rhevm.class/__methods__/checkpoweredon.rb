module ManageIQ
  module Automate
    module Transformation
      module Infrastructure
        module VM
          module RedHat
            class CheckPoweredOn
              def initialize(handle = $evm)
                @handle = handle
              end
              
              def main
                begin
                  task = @handle.root['service_template_transformation_plan_task']
                  destination_vm = @handle.vmdb(:vm).find_by(:id => task.get_option(:destination_vm_id))
                  destination_ems = destination_vm.ext_management_system
                  destination_vm_sdk = ManageIQ::Automate::Transformation::Infrastructure::VM::RedHat::Utils.new(destination_ems).vm_find_by_name(destination_vm.name)
                  @handle.log(:info, "Status of VM '#{destination_vm.name}': #{destination_vm_sdk.status}")
                  unless destination_vm_sdk.status == OvirtSDK4::VmStatus::UP
                    @handle.root["ae_result"] = "retry"
                    @handle.root["ae_retry_interval"] = "15.seconds"
                  end
                rescue Exception => e
                  @handle.set_state_var(:ae_state_progress, { 'message' => e.message })
                  raise
                end
              end
            end
          end
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  ManageIQ::Automate::Transformation::Infrastructure::VM::RedHat::CheckPoweredOn.new.main
end
