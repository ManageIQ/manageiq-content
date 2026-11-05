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
                @handle.log('info', "Checking if all service tasks have been retired.")
                check_all_service_tasks
              end

              private

              def log_task_info(task)
                @handle.log('info', "Service Retire Task <#{task.id}> <#{task.description}> is not retired, setting retry.")
                task.miq_request_tasks.each do |t|
                  @handle.log('info', "  Service Retire Task <#{task.id}> is waiting on <#{t.request_type}> Task <#{t.id}> <#{t.description}>") if t.state != 'finished'
                end
              end

              def check_all_service_tasks
                task = @handle.root['service_retire_task']
                task_status = task['status']
                result = task.statemachine_task_status

                @handle.log('info', "Service RetireCheck with <#{result}> for state <#{task.state}> and status <#{task_status}>")

                if task.miq_request_tasks.all? { |t| t.state == 'finished' }
                  if result == 'error' || error_tasks(task).present?
                    result = 'error'
                    @handle.log('error', "Retirement failed with errors.")
                  else
                    result = 'ok'
                    @handle.log('info', "Child tasks finished.")
                  end
                end

                case result
                when 'error'
                  @handle.root['ae_result'] = 'error'
                  reason = @handle.root['service_retire_task'].message
                  reason = error_tasks(task).first.message if reason.blank? && error_tasks(task).present?
                  reason = reason[7..] if reason && reason[0..6] == 'Error: '
                  @handle.root['ae_reason'] = reason
                when 'retry'
                  log_task_info(task)
                  @handle.root['ae_result']         = 'retry'
                  @handle.root['ae_retry_interval'] = '1.minute'
                when 'ok'
                  # Bump State
                  @handle.root['ae_result'] = 'ok'
                end
              end

              def error_tasks(task)
                task.miq_request_tasks.select { |t| t.statemachine_task_status == 'error' }
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Service::Retirement::StateMachines::Methods::CheckServiceRetired.new.main
