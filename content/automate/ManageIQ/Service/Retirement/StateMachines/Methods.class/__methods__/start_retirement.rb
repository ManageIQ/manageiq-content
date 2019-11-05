#
# Description: This method sets the retirement_state to retiring
#
module ManageIQ
  module Automate
    module Service
      module Retirement
        module StateMachines
          module Methods
            class StartRetirement
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                @handle.log('info', "Service before start_retirement: #{service.inspect} ")
                start_retirement(service)
                @handle.log('info', "Service after start_retirement: #{service.inspect} ")
              end

              private

              def service
                @handle.root["service"].tap do |service|
                  raise 'Service Object not found' if service.nil?
                end
              end

              def start_retirement(service)
                service_validation(service)
                @handle.create_notification(:type => :service_retiring, :subject => service)

                service.start_retirement
              end

              def service_validation(service)
                if service.retired?
                  raise 'Service is already retired'
                end

                if service.retiring?
                  raise 'Service is already in the process of being retired'
                end

                unless @handle.root['service_retire_task']
                  raise 'Service retire task not found, The old style retirement is incompatible with the new retirement state machine.'
                end
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Service::Retirement::StateMachines::Methods::StartRetirement.new.main
