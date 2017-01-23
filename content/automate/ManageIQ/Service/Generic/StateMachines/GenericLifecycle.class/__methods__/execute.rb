#
# Description: This method executes a job template
#
module ManageIQ
  module Automate
    module Service
      module Generic
        module StateMachines
          module GenericLifecycle
            class Execute
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                @handle.log("info", "Starting execute")

                task = @handle.root["service_template_provision_task"]
                service = task.destination

                begin
                  service.execute(@handle.root["service_action"])
                  @handle.log("info", "Ending execute")
                rescue => err
                  @handle.root['ae_result'] = 'error'
                  @handle.root['ae_reason'] = err.message
                  task.miq_request.user_message = err.message
                  @handle.log("info", "Error in execute")
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
  ManageIQ::Automate::Service::Generic::StateMachines::GenericLifecycle::Execute.new.main
end
