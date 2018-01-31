#
# Description: <Method description here>
#
module ManageIQ
  module Automate
    module MigrationPlan
      module Provisioning
        module StateMachines
          module VmMigration
            class CheckProvision
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                task = @handle.root["migration_plan_provision_task"]
                task.update_migration_progress(:percentage => '40', :transferred => '500MB')
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
    VmMigration::CheckProvision.new.main
end
