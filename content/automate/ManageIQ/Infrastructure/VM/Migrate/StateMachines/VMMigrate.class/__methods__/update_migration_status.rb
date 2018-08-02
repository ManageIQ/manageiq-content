#
# Description: This method updates the migration status
#
module ManageIQ
  module Automate
    module Infrastructure
      module VM
        module Migrate
          module StateMachines
            class UpdateMigrationStatus
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                update_migration_status(task)
              end

              private

              def task
                raise "ERROR - task object not passed in" unless @handle.root['vm_migrate_task']
                @handle.root['vm_migrate_task']
              end

              def update_migration_status(task)
                status = @handle.inputs['status']

                # Update Status Message
                updated_message  = "Server [#{@handle.root['miq_server'].name}] "
                updated_message += "VM [#{task.source.name}] "
                updated_message += "Step [#{@handle.root['ae_state']}] "
                updated_message += "Status [#{status}] "
                updated_message += "Message [#{task.message}] "
                updated_message += "Current Retry Number [#{@handle.root['ae_state_retries']}]" if @handle.root['ae_result'] == 'retry'
                task.miq_request.user_message = updated_message
                task.message = status

                if @handle.root['ae_result'] == "error"
                  @handle.create_notification(:level   => "error", \
                                              :message => "VM Migration Error: #{updated_message}")
                  @handle.log(:error, "VM Migration Error: #{updated_message}")
                end

                # Update Status for on_entry,on_exit
                if @handle.root['ae_result'] == 'ok'
                  if status == 'migration_complete'
                    task.finished('VM Migrated Successfully')
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

ManageIQ::Automate::Infrastructure::VM::Migrate::StateMachines::UpdateMigrationStatus.new.main
