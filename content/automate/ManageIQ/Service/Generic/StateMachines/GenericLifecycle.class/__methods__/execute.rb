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

                begin
                  service.set_automate_timeout(@handle.field_timeout, service_action)
                  service.execute(service_action)
                  @handle.root['ae_result'] = 'ok'
                  @handle.log("info", "Ending execute")
                rescue => err
                  @handle.root['ae_result'] = 'error'
                  @handle.root['ae_reason'] = err.message
                  @handle.log('error', "Error in execute: #{err.message}")
                  update_task(err.message)
                end
              end

              private

              def update_task(message, status = nil)
                ManageIQ::Automate::Service::Generic::StateMachines::Utils::UtilObject.update_task(message, status, @handle)
              end

              def service
                ManageIQ::Automate::Service::Generic::StateMachines::Utils::UtilObject.service(@handle)
              end

              def service_action
                ManageIQ::Automate::Service::Generic::StateMachines::Utils::UtilObject.service_action(@handle)
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Service::Generic::StateMachines::GenericLifecycle::Execute.new.main
