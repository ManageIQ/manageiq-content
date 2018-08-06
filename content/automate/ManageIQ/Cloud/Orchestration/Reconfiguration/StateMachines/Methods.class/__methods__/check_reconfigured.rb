#
# Description: This method checks to see if the stack has been reconfigured
#   and whether the refresh has completed
#
module ManageIQ
  module Automate
    module Cloud
      module Orchestration
        module Reconfiguration
          module StateMachines
            module Methods
              class CheckReconfigured
                def initialize(handle = $evm)
                  @handle = handle
                end

                def main
                  task = @handle.root["service_reconfigure_task"]
                  service = task.source

                  unless service
                    @handle.log(:error, 'Service is nil')
                    raise 'Service is nil'
                  end

                  if @handle.state_var_exist?('provider_last_refresh')
                    check_refreshed(service)
                  else
                    check_updated(service)
                  end

                  task.miq_request.user_message = @handle.root['ae_reason'] unless @handle.root['ae_reason'].blank?
                end

                private

                def refresh_provider(service)
                  provider = service.orchestration_manager

                  @handle.log("info", "Refreshing provider #{provider.name}")
                  @handle.set_state_var('provider_last_refresh', provider.last_refresh_date.to_i)
                  provider.refresh
                end

                def refresh_may_have_completed?(service)
                  provider = service.orchestration_manager
                  provider.last_refresh_date.to_i > @handle.get_state_var('provider_last_refresh')
                end

                def check_stack_update_state(service)
                  # check whether the stack update has completed
                  status, reason = service.orchestration_stack_status
                  case status.downcase
                  when 'update_complete', 'create_complete'
                    @handle.root['ae_result'] = 'ok'
                    # update the orchestration_template only upon completion
                    service.orchestration_template = service.service_template.orchestration_template
                  when 'rollback_complete', 'delete_complete', /failed$/, /canceled$/
                    @handle.root['ae_result'] = 'error'
                    @handle.root['ae_reason'] = reason
                  else
                    # update not done yet in provider
                    @handle.root['ae_result']         = 'retry'
                    @handle.root['ae_retry_interval'] = '1.minute'
                    return
                  end
                end

                def check_updated(service)
                  @handle.log("info", "Check orchestration deployed")

                  check_stack_update_state(service)

                  log_msg = "Stack update finished. Status: #{@handle.root['ae_result']}, "\
                            "reason: #{@handle.root['ae_reason']}"
                  @handle.log("info", log_msg)

                  @handle.set_state_var('update_result', @handle.root['ae_result'])
                  @handle.set_state_var('update_reason', @handle.root['ae_reason'])

                  refresh_provider(service)

                  @handle.root['ae_result']         = 'retry'
                  @handle.root['ae_retry_interval'] = '30.seconds'
                end

                def check_refreshed(service)
                  @handle.log("info", "Check refresh status of stack (#{service.stack_name})")

                  if refresh_may_have_completed?(service)
                    @handle.root['ae_result'] = @handle.get_state_var('update_result')
                    @handle.root['ae_reason'] = @handle.get_state_var('update_reason')
                  else
                    @handle.root['ae_result']         = 'retry'
                    @handle.root['ae_retry_interval'] = '30.seconds'
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

ManageIQ::Automate::Cloud::Orchestration::Reconfiguration::StateMachines::Methods::CheckReconfigured.new.main
