#
# Description: This method updates the service status.
# Required inputs: status

module ManageIQ
  module Automate
    module Service
      module Generic
        module StateMachines
          module GenericLifecycle
            class UpdateStatus
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                @handle.log(:info, "Starting update_status")
                update_status(service)
                @handle.log(:info, "Ending update_status")
              end

              private

              def update_task(message, status)
                @handle.root['service_template_provision_task'].try do |task|
                  task.miq_request.user_message = message
                  task.message = status
                end
              end

              def service
                @handle.root["service"].tap do |service|
                  if service.nil?
                    ManageIQ::Automate::System::CommonMethods::Utils::LogObject.log_and_raise("ERROR - Service not found", @handle)
                  end
                end
              end

              def service_action
                @handle.root["service_action"].tap do |action|
                  unless %w(Provision Retirement Reconfigure).include?(action)
                    ManageIQ::Automate::System::CommonMethods::Utils::LogObject.log_and_raise("ERROR - Invalid service action: #{action}", @handle)
                  end
                end
              end

              def error
                @handle.root['ae_result'] == "error"
              end

              def updated_message(service, status)
                updated_message = "Server [#{@handle.root['miq_server'].name}] "
                updated_message += "Service [#{service.name}] #{service_action} "
                updated_message += "Step [#{@handle.root['ae_state']}] "
                updated_message += "Status [#{status}] "
                updated_message += "Current Retry Number [#{@handle.root['ae_state_retries']}]"\
                                    if @handle.root['ae_result'] == 'retry'
                @handle.log(:info, "Status message: #{updated_message} ")
                updated_message
              end

              def error_handling(service, message)
                ManageIQ::Automate::System::CommonMethods::Utils::LogObject.log_and_notify(:error, "Generic Service Error: #{message}", service, @handle)
                service.on_error(service_action)
              end

              def update_status(service)
                # Get status from input field status
                status = @handle.inputs['status']
                message = updated_message(service, status)
                update_task(message, status)
                error_handling(service, message) if error
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Service::Generic::StateMachines::GenericLifecycle::UpdateStatus.new.main
