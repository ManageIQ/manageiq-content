#
# Description: This method sets the service_action & creates a starting notification
#
module ManageIQ
  module Automate
    module Service
      module Generic
        module StateMachines
          module GenericLifecycle
            class ReconfigureStart
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                # set service_action in root
                @handle.root['service_action'] = service_action
                @handle.log(:info, "Start with action: #{service_action}")

                ManageIQ::Automate::System::CommonMethods::Utils::LogObject.log_and_notify(:info, "Service: #{service.name} #{service_action} Starting", service, @handle)
                @handle.root['ae_result'] = 'ok'
              end

              private

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

ManageIQ::Automate::Service::Generic::StateMachines::GenericLifecycle::ReconfigureStart.new.main
