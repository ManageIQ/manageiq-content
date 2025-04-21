#
# Description: This method created a notification
#
module ManageIQ
  module Automate
    module Service
      module Generic
        module StateMachines
          module GenericLifecycle
            class Finish
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                ManageIQ::Automate::System::CommonMethods::Utils::LogObject.log_and_notify(:info, "Service: #{service.name} #{service_action} Finished", service, @handle)
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

ManageIQ::Automate::Service::Generic::StateMachines::GenericLifecycle::Finish.new.main
