#
# Description: This class calls a refresh
#

module ManageIQ
  module Automate
    module Service
      module Generic
        module StateMachines
          module GenericLifecycle
            class Refresh
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                @handle.log(:info, "Starting Refresh")

                begin
                  service.refresh(service_action)
                  @handle.root['ae_result'] = 'ok'
                rescue => err
                  @handle.root['ae_result'] = 'error'
                  @handle.root['ae_reason'] = err.message
                  @handle.log(:error, "Error in Refresh: #{err.message}")
                  update_task(err.message)
                end
                @handle.log(:info, "Ending Refresh")
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

ManageIQ::Automate::Service::Generic::StateMachines::GenericLifecycle::Refresh.new.main
