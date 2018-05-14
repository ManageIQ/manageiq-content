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
                @handle.log('info', "Checking if all service resources have been retired.")
                check_all_service_resources
              end

              private

              def service
                @service ||= @handle.root['service'].tap do |obj|
                  if obj.nil?
                    @handle.log(:error, 'Service object not provided')
                    raise 'Service object has not been provided'
                  end
                end
              end

              def check_all_service_resources
                if all_service_resources_done?
                  @handle.root['ae_result'] = 'ok'
                else
                  @handle.log('info', "Service: #{service.name} resource is not retired, setting retry.")
                  @handle.root['ae_result'] = 'retry'
                  @handle.root['ae_retry_interval'] = '1.minute'
                end
              end

              def check_service_resource_retirement(sr)
                return 'ignore' unless process?(sr)
                @handle.log('info', "Checking if service resource for service: #{service.name} resource ID: #{sr.id} is retired")
                if sr.resource.retired?
                  @handle.log('info', "resource: #{sr.resource.name} is already retired.")
                  'ok'
                else
                  @handle.log('info', "resource: #{sr.resource.name} is not retired, setting retry.")
                  'retry'
                end
              end

              def process?(sr)
                return false if sr.resource.nil?
                return false if sr.resource_type == "Service" && @handle.vmdb(:service).find(sr[:resource_id]).has_parent
                sr.resource.respond_to?(:retired?)
              end

              def all_service_resources_done?
                service.service_resources.all? { |sr| %w(ok ignore).include?(check_service_resource_retirement(sr)) }
              end
            end
          end
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  ManageIQ::Automate::Service::Retirement::StateMachines::Methods::CheckServiceRetired.new.main
end
