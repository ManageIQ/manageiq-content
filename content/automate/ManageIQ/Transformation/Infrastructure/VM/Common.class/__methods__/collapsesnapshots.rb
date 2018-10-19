module ManageIQ
  module Automate
    module Transformation
      module Infrastructure
        module VM
          module VMware
            class CollapseSnapshots
              def initialize(handle = $evm)
                @handle = handle
                @task = ManageIQ::Automate::Transformation::Common::Utils.task(@handle)
                @source_vm = ManageIQ::Automate::Transformation::Common::Utils.source_vm(@handle)
              end

              def main
                return unless @source_vm.vendor == 'vmware'
                return if @source_vm.snapshots.empty?
                raise "VM '#{@source_vm.name}' has snapshots, but we are not allowed to collapse them. Exiting." unless @task.get_option(:collapse_snapshots)
                @source_vm.remove_all_snapshots
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

ManageIQ::Automate::Transformation::Infrastructure::VM::VMware::CollapseSnapshots.new.main
