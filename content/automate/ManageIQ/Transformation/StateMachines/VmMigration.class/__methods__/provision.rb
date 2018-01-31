#
# Description: <Method description here>
#
module ManageIQ
  module Automate
    module MigrationPlan
      module Provisioning
        module StateMachines
          module VmMigration
            class Provision
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                @handle.log("info", "Listing Root Object Attributes:")
                @handle.root.attributes.sort.each { |k, v| @handle.log("info", "\t#{k}: #{v}") }
                @handle.log("info", "===========================================")

                task = @handle.root["migration_plan_provision_task"]
                @handle.log("info", "Migration VM = #{task.source.id}")
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
    VmMigration::Provision.new.main
end
