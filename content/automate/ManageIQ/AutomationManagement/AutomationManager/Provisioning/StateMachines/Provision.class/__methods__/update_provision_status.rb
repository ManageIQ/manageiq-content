#
# Description: This method updates the service provisioning status
# Required inputs: status
#
module ManageIQ
  module Automate
    module AutomationManagement
      module AutomationManager
        module Provisioning
          module StateMachines
            module Provision
              class UpdateProvisionStatus
                def initialize(handle = $evm)
                  @handle = handle
                end

                def task
                  @task ||= @handle.root['miq_provision_task'].tap do |task|
                    unless task
                      @handle.log(:error, 'miq_provision_task object not provided')
                      exit(MIQ_STOP)
                    end
                    unless task.source
                      @handle.log(:info, task.inspect)

                      @handle.log(:error, 'miq_provision_task.source object not provided (ConfigurationScript expected)')
                      exit(MIQ_STOP)
                    end
                  end
                end

                def status_param
                  @handle.inputs['status']
                end

                def fire_notification(msg)
                  @handle.create_notification(
                    :level   => "error",
                    :subject => task.miq_request,
                    :message => "Automation Manager Provision Error: #{msg}"
                  )
                end

                def main
                  # Update Task Message
                  task.message = status_param

                  # Update Request Message
                  msg = "[#{@handle.root['miq_server'].name}] "
                  msg += "Source: [#{task.source.id}|#{task.source.manager_ref}] "
                  msg += "Step [#{@handle.root['ae_state']}] "
                  msg += "Message [#{task.message}] "
                  msg += "Current Retry Number [#{@handle.root['ae_state_retries']}]" if @handle.root['ae_result'] == 'retry'
                  task.miq_request.user_message = msg
                  @handle.log(:info, "Logging request message: #{msg}")

                  # Let user know if Request failed
                  if @handle.root['ae_result'] == "error"
                    fire_notification(msg)
                    @handle.log(:error, "AutomationManager Provision Error: #{msg}")
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

ManageIQ::Automate::AutomationManagement::AutomationManager::Provisioning::StateMachines::Provision::UpdateProvisionStatus.new.main
