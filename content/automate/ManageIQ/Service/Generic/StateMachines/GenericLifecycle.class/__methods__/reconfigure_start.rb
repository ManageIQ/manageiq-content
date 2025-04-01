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
                @handle.root["service"].tap do |service|
                  if service.nil?
                    ManageIQ::Automate::System::CommonMethods::Utils::LogObject.log_and_raise("ERROR - Service not found", @handle)
                  end
                end
              end

              def service_action
                action = @handle.root["service_action"]
                if action.nil? && (@handle.root["request"] == "service_reconfigure")
                  action = "Reconfigure"
                end
                unless %w[Provision Retirement Reconfigure].include?(action)
                  ManageIQ::Automate::System::CommonMethods::Utils::LogObject.log_and_raise("ERROR - Invalid service action: #{action}", @handle)
                end
                action
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Service::Generic::StateMachines::GenericLifecycle::ReconfigureStart.new.main
