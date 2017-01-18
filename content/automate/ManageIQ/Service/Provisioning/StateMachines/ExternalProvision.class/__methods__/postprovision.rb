#
# Description: This method examines the external provision
#
module ManageIQ
  module Automate
    module Service
      module Provisioning
        module StateMachines
          module ExternalProvision
            class PostProvision
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                @handle.log("info", "Starting External Post-Provisioning")

                task = @handle.root["service_template_provision_task"]
                service = task.destination
                service.post_provision_configure

                if @handle.inputs.fetch('debug', false)
                  dump_stack_outputs(service.orchestration_stack)
                end
              end

              def dump_stack_outputs(stack)
                @handle.log("info", "Outputs from stack #{stack.name}")
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

if __FILE__ == $PROGRAM_NAME
  ManageIQ::Automate::Service::Provisioning::StateMachines::ExternalProvision::PostProvision.new.main
end
