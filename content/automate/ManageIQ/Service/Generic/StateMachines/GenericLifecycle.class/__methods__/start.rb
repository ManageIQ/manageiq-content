#
# Description: This method creates a starting notification
#
module ManageIQ
  module Automate
    module Service
      module Generic
        module StateMachines
          module GenericLifecycle
            class Start
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                msg = "Service: #{service.name} #{service_action} Starting"
                @handle.log('info', msg)
                @handle.create_notification(:level => 'info', :subject => service, :message => msg)
                @handle.root['ae_result'] = 'ok'
              end

              private

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

ManageIQ::Automate::Service::Generic::StateMachines::GenericLifecycle::Start.new.main
