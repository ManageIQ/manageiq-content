module ManageIQ
  module Automate
    module Transformation
      module Infrastructure
        module VM
          module VMware
            class CollapseSnapshots
              def initialize(handle = $evm)
                @handle = handle
              end
          
              def main
                begin
                  task = @handle.root['service_template_transformation_plan_task']
                  source_vm = task.source
            
                  if source_vm.snapshots.empty?
                    @handle.log(:info, "VM '#{source_vm.name}' has no snapshot. Nothing to do.")
                  elsif task.get_option(:collapse_snapshots)
                    @handle.log(:info, "VM '#{source_vm.name}' has snapshots and we need to collapse them.")
                    @handle.log(:info, "Collapsing snapshots for #{source_vm.name}")
                    source_vm.remove_all_snapshots
                  else
                    raise "VM '#{source_vm.name}' has snapshots, but we are not allowed to collapse them. Exiting."
                  end
                rescue Exception => e
                  @handle.set_state_var(:ae_state_progress, { 'message' => e.message })
                  raise
                end
              end
            end
          end
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  ManageIQ::Automate::Transformation::Infrastructure::VM::VMware::CollapseSnapshots.new.main
end
