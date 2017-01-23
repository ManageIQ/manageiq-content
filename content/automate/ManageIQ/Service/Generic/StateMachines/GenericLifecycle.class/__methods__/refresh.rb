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
                task = @handle.root["service_template_provision_task"]
                service = task.try(:destination)

                unless service
                  @handle.log(:error, 'Service is nil')
                  raise 'Service is nil'
                end

                @handle.log("info", "Starting Refresh")
                service.refresh(@handle.root["service_action"])
                @handle.log("info", "Ending Refresh")
              end
            end
          end
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  ManageIQ::Automate::Service::Generic::StateMachines::GenericLifecycle::Refresh.new.main
end
