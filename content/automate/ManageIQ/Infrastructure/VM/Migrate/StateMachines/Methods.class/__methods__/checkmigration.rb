#
# Description: This method checks to see if the VM has been migrated
#

module ManageIQ
  module Automate
    module Infrastructure
      module VM
        module Migrate
          module StateMachines
            class Checkmigration
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                checkmigration(task)
              end

              private

              def task
                raise "ERROR - task object not passed in" unless @handle.root['vm_migrate_task']
                @handle.root['vm_migrate_task']
              end

              def checkmigration(task)
                task_status = task['status']
                result = task.statemachine_task_status

                @handle.log('info', "CheckMigration returned <#{result}> for state <#{task.state}> and status <#{task_status}>")

                case result
                when 'error'
                  @handle.root['ae_result'] = 'error'
                  reason = @handle.root['vm_migrate_task'].message
                  reason = reason[7..-1] if reason[0..6] == 'Error: '
                  @handle.root['ae_reason'] = reason
                when 'retry'
                  @handle.root['ae_retry_interval'] = 1.minute
                  @handle.root['ae_result'] = 'retry'
                when 'ok'
                  # Bump State
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

ManageIQ::Automate::Infrastructure::VM::Migrate::StateMachines::Checkmigration.new.main
