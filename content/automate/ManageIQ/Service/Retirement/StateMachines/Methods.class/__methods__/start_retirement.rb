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
                @handle.log('info', "Service Start Retirement for #{service.inspect}.try")
                @handle.create_notification(:type => :service_retiring, :subject => service)
                service.start_retirement

                @handle.log('info', "Service after start_retirement: #{service.inspect} ")
              end

              private

              def service
                @service ||= @handle.root["service"].tap do |service|
                  if service.nil?
                    @handle.log(:error, 'Service Object not found')
                    raise 'Service Object not found'
                  end
                  if service.retired?
                    @handle.log(:error, 'Service is already retired. Aborting current State Machine.')
                    raise 'Service is already retired. Aborting current State Machine.'
                  end
                  if service.retiring?
                    @handle.log(:error, 'Service is in the process of being retired. Aborting current State Machine.')
                    raise 'Service is in the process of being retired. Aborting current State Machine.'
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

ManageIQ::Automate::Service::Retirement::StateMachines::Methods::StartRetirement.new.main
