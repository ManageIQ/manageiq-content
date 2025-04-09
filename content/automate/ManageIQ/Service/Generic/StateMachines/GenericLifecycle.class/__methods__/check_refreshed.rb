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

              def update_task(message, status = nil)
                ManageIQ::Automate::Service::Generic::StateMachines::Utils::UtilObject.update_task(message, status, @handle)
              end

              def service
                ManageIQ::Automate::Service::Generic::StateMachines::Utils::UtilObject.service(@handle)
              end

              def service_action
                ManageIQ::Automate::Service::Generic::StateMachines::Utils::UtilObject.service_action(@handle)
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
