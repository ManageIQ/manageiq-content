module ManageIQ
  module Automate
    module Transformation
      module Common
        class AssessTransformation
          def initialize(handle = $evm)
            @handle = handle
            @task = ManageIQ::Automate::Transformation::Common::Utils.task(@handle)
            @source_vm = ManageIQ::Automate::Transformation::Common::Utils.source_vm(@handle)
          end

          def populate_task_options
            @task.set_option(:source_vm_power_state, @source_vm.power_state)
            @task.set_option(:collapse_snapshots, true)
            @task.set_option(:power_off, true)
          end

          def populate_state_vars
            @handle.set_state_var(:source_ems_type, @task.source_ems.emstype)
            @handle.set_state_var(:destination_ems_type, @task.destination_ems.emstype)
          end

          def populate_factory_config
            factory_config = {
              'vmtransformation_check_interval' => @handle.object['vmtransformation_check_interval'] || '15.seconds',
              'vmpoweroff_check_interval'       => @handle.object['vmpoweroff_check_interval'] || '30.seconds'
            }
            @handle.set_state_var(:factory_config, factory_config)
          end

          def main
            @task.preflight_check
            %w(task_options state_vars factory_config).each { |ci| send("populate_#{ci}") }
          rescue => e
            @handle.set_state_var(:ae_state_progress, 'message' => e.message)
            raise
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Transformation::Common::AssessTransformation.new.main
