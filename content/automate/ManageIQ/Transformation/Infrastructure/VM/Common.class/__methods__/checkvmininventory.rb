module ManageIQ
  module Automate
    module Transformation
      module Infrastructure
        module VM
          module Common
            class CheckVmInInventory
              def initialize(handle = $evm)
                @handle = handle
              end

              def log_and_raise(message)
                @handle.log(:error, message)
                raise "ERROR - #{message}"
              end

              def task
                @task ||= @handle.root["service_template_transformation_plan_task"].tap do |task|
                  log_and_raise('A service_template_transformation_plan_task is needed for this method to continue') if task.nil?
                end
              end

              def source_vm
                @source_vm ||= task.source.tap do |vm|
                  log_and_raise('Source VM has not been defined in the task') if vm.nil?
                end
              end

              def destination_vm
                destination_ems = task.transformation_destination(source_vm.ems_cluster).ext_management_system
                @destination_vm ||= @handle.vmdb(:vm).find_by(:name => source_vm.name, :ems_id => destination_ems.id)
              end

              def set_retry(message = nil, interval = '1.minutes')
                @handle.log(:info, message) if message.present?
                @handle.root['ae_result'] = 'retry'
                @handle.root['ae_retry_interval'] = interval
              end

              def main
                if destination_vm.blank?
                  set_retry('VM is not yet in the destination provider inventory', '15.seconds')
                else
                  task.set_option(:destination_vm_id, destination_vm.id)
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

ManageIQ::Automate::Transformation::Infrastructure::VM::Common::CheckVmInInventory.new.main
