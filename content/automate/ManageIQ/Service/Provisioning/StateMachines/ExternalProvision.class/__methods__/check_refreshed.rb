#
# Description: This class checks to see if the refresh has completed
#
module ManageIQ
  module Automate
    module Service
      module Provisioning
        module StateMachines
          module ExternalProvision
            class CheckRefreshed
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

                unless service.instance_of?(MiqAeMethodService::MiqAeServiceServiceOrchestration)
                  @handle.log(:error, 'Service has a different type from MiqAeServiceServiceOrchestration')
                  raise 'Service has a different type from MiqAeServiceServiceOrchestration'
                end

                check_refreshed(service)

                unless @handle.root['ae_reason'].blank?
                  task.miq_request.user_message = @handle.root['ae_reason'].truncate(255)
                end
              end

              private

              def refresh_may_have_completed?(service)
                stack = service.orchestration_stack
                refreshed_stack = @handle.vmdb(:orchestration_stack).find_by(:name    => stack.name,
                                                                             :ems_ref => stack.ems_ref)
                refreshed_stack && refreshed_stack.status != 'CREATE_IN_PROGRESS'
              end

              def check_refreshed(service)
                @handle.log("info", "Check refresh status of stack (#{service.stack_name})")

                if refresh_may_have_completed?(service)
                  @handle.root['ae_result'] = @handle.get_state_var('deploy_result')
                  @handle.root['ae_reason'] = @handle.get_state_var('deploy_reason')
                  @handle.log("info", "Refresh completed.")
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

if __FILE__ == $PROGRAM_NAME
  ManageIQ::Automate::Service::Provisioning::StateMachines::ExternalProvision::CheckRefreshed.new.main
end
