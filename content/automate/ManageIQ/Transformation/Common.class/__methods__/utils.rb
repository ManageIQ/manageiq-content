module ManageIQ
  module Automate
    module Transformation
      module Common
        class Utils
          STATE_MACHINE_PHASES = %w(transformation cleanup).freeze

          def self.log_and_raise(message, handle = $evm)
            handle.log(:error, message)
            raise "ERROR - #{message}"
          end

          def self.transformation_phase(handle = $evm)
            @transformation_phase ||= handle.root['state_machine_phase'].tap do |phase|
              log_and_raise('Transformation phase is not valid', handle) if STATE_MACHINE_PHASES.exclude?(phase)
            end
          end

          def self.task(handle = $evm)
            send("#{transformation_phase(handle)}_task", handle)
          end

          def self.transformation_task(handle = $evm)
            @task ||= handle.root['service_template_transformation_plan_task'].tap do |task|
              log_and_raise('A service_template_transformation_plan_task is needed for this method to continue', handle) if task.nil?
            end
          end

          def self.cleanup_task(handle = $evm)
            log_and_raise('service_template_transformation_plan_task_id is not defined', handle) if handle.root['service_template_transformation_plan_task_id'].nil?
            @task ||= handle.vmdb(:service_template_transformation_plan_task).find_by(:id => handle.root['service_template_transformation_plan_task_id']).tap do |task|
              log_and_raise('A service_template_transformation_plan_task is needed for this method to continue', handle) if task.nil?
            end
          end

          def self.source_vm(handle = $evm)
            @source_vm ||= task(handle).source.tap do |vm|
              log_and_raise('Source VM has not been defined in the task', handle) if vm.nil?
            end
          end

          def self.destination_vm(handle = $evm)
            destination_vm_id = task(handle).get_option(:destination_vm_id)
            return if destination_vm_id.nil?
            @destination_vm ||= handle.vmdb(:vm).find_by(:id => destination_vm_id).tap do |vm|
              log_and_raise("No match for destination_vm_id in VMDB", handle) if vm.nil?
            end
          end
        end
      end
    end
  end
end
