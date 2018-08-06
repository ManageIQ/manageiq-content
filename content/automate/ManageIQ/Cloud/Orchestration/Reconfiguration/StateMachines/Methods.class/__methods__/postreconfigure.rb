#
# Description: This method examines the orchestration stack reconfigured
#
module ManageIQ
  module Automate
    module Cloud
      module Orchestration
        module Reconfiguration
          module StateMachines
            class PostReconfigure
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                @handle.log("info", "Starting Orchestration Post-Reconfiguration")

                if @handle.inputs.fetch('debug', false)
                  dump_stack_outputs(stack)
                end
              end

              private

              def log_and_raise(obj_name)
                @handle.log(:error, "#{obj_name} is nil")
                raise "#{obj_name} not found"
              end

              def stack
                task = @handle.root['service_reconfigure_task']
                log_and_raise('Service Reconfigure Task') if task.nil?

                source = task.source
                log_and_raise('Service') if source.nil?

                orchestration_stack = source.orchestration_stack
                log_and_raise('Orchestration Stack') if orchestration_stack.nil?

                orchestration_stack
              end

              def dump_stack_outputs(stack)
                @handle.log("info", "Outputs from updated stack #{stack.name}")
                stack.outputs.each do |output|
                  @handle.log("info", "Key #{output.key}, value #{output.value}")
                end
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Cloud::Orchestration::Reconfiguration::StateMachines::PostReconfigure.new.main
