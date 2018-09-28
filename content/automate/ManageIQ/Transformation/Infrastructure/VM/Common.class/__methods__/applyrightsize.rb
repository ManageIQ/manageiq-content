module ManageIQ
  module Automate
    module Transformation
      module Infrastructure
        module VM
          module Common
            class ApplyRightSize
              RIGHT_SIZE_ITEMS = %i(cpu memory).freeze

              def initialize(handle = $evm)
                @handle = handle
                @task = ManageIQ::Automate::Transformation::Common::Utils.task(@handle)
                @source_vm = ManageIQ::Automate::Transformation::Common::Utils.source_vm(@handle)
                @destination_vm = ManageIQ::Automate::Transformation::Common::Utils.destination_vm(@handle)
              end

              def apply_right_size_cpu(strategy)
                @destination_vm.set_number_of_cpus(@source_vm.send("#{strategy}_recommended_vcpus"), :sync => true)
              end

              def apply_right_size_memory(strategy)
                @destination_vm.set_memory(@source_vm.send("#{strategy}_recommended_mem"), :sync => true)
              end

              def main
                RIGHT_SIZE_ITEMS.each do |item|
                  right_size_strategy = @task.get_option("right_size_strategy_#{item}".to_sym)
                  send("apply_right_size_#{item}", right_size_strategy) if right_size_strategy
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

ManageIQ::Automate::Transformation::Infrastructure::VM::Common::ApplyRightSize.new.main
