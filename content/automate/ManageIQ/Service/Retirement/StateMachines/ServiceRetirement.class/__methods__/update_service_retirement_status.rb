module ManageIQ
  module Automate
    module Service
      module Retirement
        module StateMachines
          module ServiceRetirement
            class UpdateServiceRetirementStatus
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                task = @handle.root['service_retire_task']

                updated_message = update_status_message(task, @handle.inputs['status'])

                if @handle.root['ae_result'] == "error"
                  @handle.create_notification(:level   => "error",
                                              :subject => task.miq_request,
                                              :message => "Service Retire Error: #{updated_message}")
                  @handle.log(:error, "Service Retire Error: #{updated_message}")
                end
              end

              private

              def update_status_message(task, status)
                updated_message  = "Server [#{@handle.root['miq_server'].name}] "
                updated_message += "Step [#{@handle.root['ae_state']}] "
                updated_message += "Status [#{status}] "
                updated_message += "Message [#{task.message}] " if task
                updated_message += "Current Retry Number [#{@handle.root['ae_state_retries']}]"\
                                    if @handle.root['ae_result'] == 'retry'
                if task
                  task.miq_request.user_message = updated_message
                  task.message = status

                  updated_message
                end
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Service::Retirement::StateMachines::ServiceRetirement::UpdateServiceRetirementStatus.new.main
