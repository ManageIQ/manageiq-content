module ManageIQ
  module Automate
    module Service
      module Retirement
        module StateMachines
          module Methods
            class CheckServiceRetired
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                service

                @handle.log('info', "Checking if all service resources have been retired.")
                result = 'ok'
                service.service_resources.each do |sr|
                  next if sr.resource.nil?
                  next if sr.resource_type == "Service" && @handle.vmdb(:service).find(sr[:resource_id]).has_parent
                  next unless sr.resource.respond_to?(:retired?)
                  result = check_service_resource_retirement(sr)
                end

                @handle.log('info', "Service: #{service.name} Resource retirement check returned <#{result}>")
                result(result)
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

              def check_service_resource_retirement(sr)
                @handle.log('info', "Checking if service resource for service: #{service.name} resource ID: #{sr.id} is retired")
                if sr.resource.retired?
                  @handle.log('info', "resource: #{sr.resource.name} is already retired.")
                  'ok'
                else
                  @handle.log('info', "resource: #{sr.resource.name} is not retired, setting retry.")
                  'retry'
                end
              end

              def result(param)
                case param
                when 'retry'
                  @handle.log('info', "Service: #{service.name} resource is not retired, setting retry.")
                  @handle.root['ae_result']         = 'retry'
                  @handle.root['ae_retry_interval'] = '1.minute'
                when 'ok'
                  @handle.log('info', "All resources are retired for service: #{service.name}. ")
                  @handle.root['ae_result'] = 'ok'
                end
              end
            end
          end
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  ManageIQ::Automate::Service::Retirement::StateMachines::Methods::CheckServiceRetired.new.main
end
