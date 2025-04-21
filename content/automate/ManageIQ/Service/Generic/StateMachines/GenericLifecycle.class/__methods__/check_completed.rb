#
# Description: This class checks to see if the external provision has completed
#
module ManageIQ
  module Automate
    module Service
      module Generic
        module StateMachines
          module GenericLifecycle
            class CheckCompleted
              MIN_RETRY_INTERVAL = 1
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                @handle.log("info", "Starting check_completed")
                check_completed(service)
                @handle.log("info", "Ending check_completed")
              end

              private

              def update_task(message, status = nil)
                ManageIQ::Automate::Service::Generic::StateMachines::Utils::UtilObject.update_task(message, status, @handle)
              end

              def service
                ManageIQ::Automate::Service::Generic::StateMachines::Utils::UtilObject.service(@handle)
              end

              def service_action
                ManageIQ::Automate::Service::Generic::StateMachines::Utils::UtilObject.service_action(@handle)
              end

              def execution_ttl
                service.options[:config_info][service_action.downcase.to_sym][:execution_ttl].to_i
              end

              def retry_interval
                @handle.root['ae_retry_interval'] = 1.minute
                ttl = execution_ttl
                max_retry_count = @handle.root['ae_state_max_retries']
                return if ttl.zero? || max_retry_count.zero?

                interval = ttl / max_retry_count.to_f
                if interval > MIN_RETRY_INTERVAL
                  @handle.log('info', "Setting retry interval to #{interval} time to live #{ttl} / #{max_retry_count}")
                  @handle.root['ae_retry_interval'] = interval.minutes
                end
              end

              def check_completed(service)
                done, message = service.check_completed(service_action)
                if done
                  if message.blank?
                    @handle.root['ae_result'] = 'ok'
                  else
                    @handle.root['ae_result'] = 'error'
                    @handle.root['ae_reason'] = message
                    @handle.log(:error, "Error in check completed: #{message}")
                    update_task(message)
                  end
                else
                  @handle.root['ae_result'] = 'retry'
                  retry_interval
                end
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Service::Generic::StateMachines::GenericLifecycle::CheckCompleted.new.main
