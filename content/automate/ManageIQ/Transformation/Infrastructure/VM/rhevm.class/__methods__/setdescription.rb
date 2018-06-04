module ManageIQ
  module Automate
    module Transformation
      module Infrastructure
        module VM
          module RedHat
            class SetDescription
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                task = @handle.root['service_template_transformation_plan_task']
                destination_vm = @handle.vmdb(:vm).find_by(:id => task.get_option(:destination_vm_id))
                destination_ems = destination_vm.ext_management_system

                description = "Migrated by Cloudforms on #{Time.now.utc}."
                ManageIQ::Automate::Transformation::Infrastructure::VM::RedHat::Utils.new(destination_ems).vm_set_description(destination_vm, description)
              rescue => e
                @handle.set_state_var(:ae_state_progress, 'message' => e.message)
                raise
              end
            end
          end
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  ManageIQ::Automate::Transformation::Infrastructure::VM::RedHat::SetDescription.new.main
end
