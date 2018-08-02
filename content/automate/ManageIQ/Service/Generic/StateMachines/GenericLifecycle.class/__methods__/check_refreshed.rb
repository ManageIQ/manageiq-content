#
# Description: This class checks to see if the refresh has completed
#
module ManageIQ
  module Automate
    module Service
      module Generic
        module StateMachines
          module GenericLifecycle
            class CheckRefreshed
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                @handle.log("info", "Starting Check Refreshed")
                check_refreshed(service)
                @handle.log("info", "Ending Check Refreshed")
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

              def check_refreshed(service)
                done, message = service.check_refreshed(service_action)
                if done
                  if message.blank?
                    @handle.root['ae_result'] = 'ok'
                  else
                    @handle.root['ae_result'] = 'error'
                    @handle.root['ae_reason'] = message
                    @handle.log(:error, "Error in check refreshed: #{message}")
                    update_task(message)
                  end
                else
                  @handle.root['ae_result'] = 'retry'
                end
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Service::Generic::StateMachines::GenericLifecycle::CheckRefreshed.new.main
