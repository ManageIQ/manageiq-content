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
                @handle.log("info", "Starting PostProcess")

                begin
                  service.postprocess(@handle.root["service_action"])
                  @handle.root['ae_result'] = 'ok'
                rescue => err
                  @handle.root['ae_result'] = 'error'
                  @handle.root['ae_reason'] = err.message
                  task.miq_request.user_message = err.message
                  @handle.log(:error, "Error in PostProcess: #{err.message}")
                end
                @handle.log("info", "Ending PostProcess")
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
