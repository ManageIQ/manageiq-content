#
# Description: This method marks the service as retired
#

module ManageIQ
  module Automate
    module Service
      module Retirement
        module StateMachines
          module Methods
            class FinishRetirement
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                finish_retirement(service)
              end

              private

              def service
                @handle.root["service"].tap do |service|
                  # Not raising an error since this is the finish state.
                  @handle.log(:warn, "Service Object not found") if service.nil?
                end
              end

              def finish_retirement(service)
                if service
                  service.finish_retirement
                  @handle.create_notification(:type => :service_retired, :subject => service)
                end
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Service::Retirement::StateMachines::Methods::FinishRetirement.new.main
