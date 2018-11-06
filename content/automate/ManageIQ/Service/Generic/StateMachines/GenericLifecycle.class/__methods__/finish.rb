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
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Service::Generic::StateMachines::GenericLifecycle::Finish.new.main
