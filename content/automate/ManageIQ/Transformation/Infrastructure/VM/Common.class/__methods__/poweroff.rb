module ManageIQ
  module Automate
    module Transformation
      module Infrastructure
        module VM
          module Common
            class PowerOff
              def initialize(handle = $evm)
                @handle = handle
              end
          
              def main
                begin
                  task = @handle.root['service_template_transformation_plan_task']
                  source_vm = task.source
            
                  if source_vm.power_state == 'off'
                    @handle.log(:info, "VM '#{source_vm.name}' is already off. Nothing to do.")
                  else
                    if task.get_option(:power_off)
                      @handle.log(:info, "VM '#{source_vm.name} is powered on. Let's shut it down.")
                      if @handle.state_var_exist?(:vm_shutdown_in_progress)
                        source_vm.stop if @handle.root['ae_state_retries'].to_i > 10
                      else
                        source_vm.shutdown_guest
                        @handle.set_state_var(:vm_shutdown_in_progress, true)
                      end
                      @handle.root['ae_result'] = 'retry'
                    else
                      raise "VM '#{source_vm.name} is powered on, but we are not allowed to shut it down. Aborting."
                    end
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
  ManageIQ::Automate::Transformation::Infrastructure::VM::Common::PowerOff.new.main
end
