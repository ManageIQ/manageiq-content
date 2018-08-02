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
                  service.postprocess(service_action)
                  @handle.root['ae_result'] = 'ok'
                rescue => err
                  @handle.root['ae_result'] = 'error'
                  @handle.root['ae_reason'] = err.message
                  @handle.log(:error, "Error in PostProcess: #{err.message}")
                  update_task(err.message)
                end
                @handle.log("info", "Ending PostProcess")
              end

              private

              def update_task(message)
                @handle.root['service_template_provision_task'].try { |task| task.miq_request.user_message = message }
              end

              def service
                @handle.root["service"].tap do |service|
                  if service.nil?
                    @handle.log(:error, 'Service is nil')
                    raise 'Service not found'
                  end
                end
              end

              def service_action
                @handle.root["service_action"].tap do |action|
                  unless %w(Provision Retirement Reconfigure).include?(action)
                    @handle.log(:error, "Invalid service action: #{action}")
                    raise "Invalid service_action"
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

ManageIQ::Automate::Service::Generic::StateMachines::GenericLifecycle::PostProcess.new.main
