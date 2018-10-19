module ManageIQ
  module Automate
    module Transformation
      module Infrastructure
        module VM
          module Common
            class PowerOff
              def initialize(handle = $evm)
                @handle = handle
                @task = ManageIQ::Automate::Transformation::Common::Utils.task(@handle)
                @source_vm = ManageIQ::Automate::Transformation::Common::Utils.source_vm(@handle)
              end

              def main
                return if @source_vm.power_state == 'off'
                raise "VM '#{@source_vm.name} is powered on, but we are not allowed to shut it down. Aborting." unless @task.get_option(:power_off)
                if @handle.state_var_exist?(:vm_shutdown_in_progress)
                  @source_vm.stop if @handle.root['ae_state_retries'].to_i > 10
                else
                  @source_vm.shutdown_guest
                  @handle.set_state_var(:vm_shutdown_in_progress, true)
                end
                @handle.root['ae_result'] = 'retry'
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

ManageIQ::Automate::Transformation::Infrastructure::VM::Common::PowerOff.new.main
