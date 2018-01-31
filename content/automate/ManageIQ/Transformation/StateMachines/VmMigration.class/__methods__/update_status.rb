#
# Description: This method updates the migration plan provision status.
# Required inputs: status
#
module ManageIQ
  module Automate
    module MigrationPlan
      module Provisioning
        module StateMachines
          module VmMigration
            class UpdateStatus
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                prov = @handle.root['migration_plan_provision_task']

                if prov.nil?
                  @handle.log(:error, "migration_plan_provision_task object not provided")
                  raise "migration_plan_provision_task object not provided"
                end

                updated_message = update_status_message(prov, @handle.inputs['status'])

                if @handle.root['ae_result'] == "error"
                  @handle.create_notification(:level   => "error",
                                              :subject => prov.miq_request,
                                              :message => "Migration Plan Provision Error: #{updated_message}")
                  @handle.log(:error, "Migration Plan Provision Error: #{updated_message}")
                end
              end

              private

              def update_status_message(prov, status)
                updated_message  = "Server [#{@handle.root['miq_server'].name}] "
                updated_message += "Step [#{@handle.root['ae_state']}] "
                updated_message += "Status [#{status}] "
                updated_message += "Message [#{prov.message}] "
                updated_message += "Current Retry Number [#{@handle.root['ae_state_retries']}]"\
                                    if @handle.root['ae_result'] == 'retry'
                prov.miq_request.user_message = updated_message
                prov.message = status

                updated_message
              end
            end
          end
        end
      end
    end
  end
end
if $PROGRAM_NAME == __FILE__
  ManageIQ::Automate::MigrationPlan::Provisioning::StateMachines::
    VmMigration::UpdateStatus.new.main
end
