module ManageIQ
  module Automate
    module Transformation
      module Infrastructure
        module VM
          module Common
            class CheckPoweredOn
              def initialize(handle = $evm)
                @handle = handle
                @task = ManageIQ::Automate::Transformation::Common::Utils.task(@handle)
                transformation_phase = ManageIQ::Automate::Transformation::Common::Utils.transformation_phase(@handle)
                case transformation_phase
                when 'transformation'
                  @vm = ManageIQ::Automate::Transformation::Common::Utils.destination_vm(@handle)
                when 'cleanup'
                  @vm = ManageIQ::Automate::Transformation::Common::Utils.source_vm(@handle)
                end
              end

              def main
                return if @vm.blank?
                return if @task.get_option(:source_vm_power_state) != 'on'
                if @vm.power_state != 'on'
                  @handle.root["ae_result"] = "retry"
                  @handle.root["ae_retry_interval"] = "15.seconds"
                end
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

ManageIQ::Automate::Transformation::Infrastructure::VM::Common::CheckPoweredOn.new.main
