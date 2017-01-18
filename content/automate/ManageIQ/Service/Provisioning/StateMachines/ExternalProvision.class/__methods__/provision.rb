#
# Description: This method launches a provisioning job
#
module ManageIQ
  module Automate
    module Service
      module Provisioning
        module StateMachines
          module ExternalProvision
            class Provision
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                @handle.log("info", "Starting External Provisioning")

                task = @handle.root["service_template_provision_task"]
                service = task.destination

                begin
                  stack = service.deploy_orchestration_stack
                  @handle.log("info",
                              "Stack #{service.stack_name} with reference id (#{stack.ems_ref}) is being created")
                rescue => err
                  @handle.root['ae_result'] = 'error'
                  @handle.root['ae_reason'] = err.message
                  task.miq_request.user_message = err.message.truncate(255)
                  @handle.log("error", "Stack #{service.stack_name} creation failed. Reason: #{err.message}")
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
  ManageIQ::Automate::Service::Provisioning::StateMachines::ExternalProvision::Provision.new.main
end
