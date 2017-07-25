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
              MIN_RETRY_INTERVAL = 1.minute
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                msg = "Service: #{service.name} #{service_action} Starting"
                @handle.log('info', msg)
                @handle.create_notification(:level => 'info', :subject => service, :message => msg)
                @handle.root['ae_result'] = 'ok'
                retry_interval
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

              def execution_ttl
                service.options[:config_info][service_action.downcase.to_sym][:execution_ttl].to_i
              end

              def retry_interval
                ttl = execution_ttl
                max_retry_count = @handle.root['ae_state_max_retries']
                return if ttl.zero? || max_retry_count.zero?

                interval = ttl / max_retry_count
                if interval > MIN_RETRY_INTERVAL
                  @handle.log('info', "Setting retry interval to #{interval} time to live #{ttl} / #{max_retry_count}")
                  @handle.root['ae_retry_interval'] = interval
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

if __FILE__ == $PROGRAM_NAME
  ManageIQ::Automate::Service::Generic::StateMachines::GenericLifecycle::Start.new.main
end
