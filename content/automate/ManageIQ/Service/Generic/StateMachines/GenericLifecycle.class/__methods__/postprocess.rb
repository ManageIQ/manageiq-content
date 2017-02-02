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
                service.postprocess(@handle.root["service_action"])
                @handle.log("info", "Ending PostProcessing")
              end

              private

              def task
                @handle.root["service_template_provision_task"].tap do |task|
                  if task.nil?
                    @handle.log(:error, 'service_template_provision_task is nil')
                    raise "service_template_provision_task not found"
                  end
                end
              end

              def service
                task.destination.tap do |service|
                  if service.nil?
                    @handle.log(:error, 'Service is nil')
                    raise 'Service not found'
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

if __FILE__ == $PROGRAM_NAME
  ManageIQ::Automate::Service::Generic::StateMachines::GenericLifecycle::PostProcess.new.main
end
