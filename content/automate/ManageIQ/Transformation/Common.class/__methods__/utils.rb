module ManageIQ
  module Automate
    module Transformation
      module Common
        class Utils
          def self.migration_phase(handle = $evm)
            return 'migration' if handle.root['service_template_transformation_plan_task'].present?
            return 'cleanup' if handle.root['service_template_transformation_plan_task_id'].present?
            raise 'Migration phase is not valid'
          end

          def self.task_and_vm(vm_type, handle = $evm)
            task = send("task_in_#{migration_phase(handle)}", handle)
            vm = send("vm_at_#{vm_type}", task, handle) if task.present?
            return task, vm
          end

          def self.task_in_migration(handle = $evm)
            handle.root['service_template_transformation_plan_task']
          end

          def self.task_in_cleanup(handle = $evm)
            handle.vmdb(:service_template_transformation_plan_task).find_by(:id => handle.root['service_template_transformation_plan_task_id'])
          end

          def self.vm_at_source(task, handle = $evm)
            task.source
          end

          def self.vm_at_destination(task, handle = $evm)
            return if task.get_option(:destination_vm_id).nil?
            handle.vmdb(:vm).find_by(:id => task.get_option(:destination_vm_id))
          end
        end
      end
    end
  end
end
