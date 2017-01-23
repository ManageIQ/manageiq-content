#
# Description: This method examines the orchestration stack provisioned
#
module ManageIQ
  module Automate
    module Service
      module Generic
        module StateMachines
          module GenericLifecycle
            class PostProcess
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                @handle.log("info", "Starting PostProcessing")

                task = @handle.root["service_template_provision_task"]
                service = task.destination

                service.postprocess(@handle.root["service_action"])
                @handle.log("info", "Ending PostProcessing")
              end
            end
          end
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  ManageIQ::Automate::Service::Generic::StateMachines::GenericLifecycle::PostProcess.new.main
end
