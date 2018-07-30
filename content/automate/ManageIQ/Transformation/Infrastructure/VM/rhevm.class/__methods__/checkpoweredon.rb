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
                task = @handle.root['service_template_transformation_plan_task']
                task ||= @handle.vmdb(:service_template_transformation_plan_task).find_by(:id => @handle.root['service_template_transformation_plan_task_id'])
                if task.get_option(:source_vm_power_state) == 'on'
                  destination_vm = @handle.vmdb(:vm).find_by(:id => task.get_option(:destination_vm_id))
                  unless destination_vm.power_state == 'on'
                    @handle.root["ae_result"] = "retry"
                    @handle.root["ae_retry_interval"] = "15.seconds"
                  end
                end
              rescue => e
                @handle.set_state_var(:ae_state_progress, 'message' => e.message)
                raise
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
