module ManageIQ
  module Automate
    module Transformation
      module Infrastructure
        module VM
          module Common
            class RestoreVmAttributes
              IDENTITY_ITEMS = %w(service tags custom_attributes ownership retirement).freeze

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
                @vm ||= task.source.tap do |vm|
                  log_and_raise('Source VM has not been defined in the task') if vm.nil?
                end
              end

              def destination_vm
                log_and_raise('destination_vm_id is blank') if task.get_option(:destination_vm_id).blank?
                @destination_vm ||= @handle.vmdb(:vm).find_by(:id => task.get_option(:destination_vm_id)).tap do |vm|
                  log_and_raise('Destination VM not found in the database after migration') if vm.nil?
                end
              end

              def vm_restore_service(source_vm, destination_vm)
                if source_vm.service
                  destination_vm.add_to_service(source_vm.service)
                  source_vm.remove_from_service
                end
              end

              def vm_restore_tags(source_vm, destination_vm)
                source_vm.tags.each do |tag|
                  destination_vm.tag_assign(tag) unless tag =~ /^folder_path_/
                end
              end

              def vm_restore_custom_attributes(source_vm, destination_vm)
                source_vm.custom_keys.each do |ca|
                  destination_vm.custom_set(ca, source_vm.custom_get(ca))
                end
              end

              def vm_restore_ownership(source_vm, destination_vm)
                owner = source_vm.owner
                miq_group = @handle.vmdb(:miq_group).find_by(:id => source_vm.miq_group_id)
                destination_vm.owner = owner if owner.present?
                destination_vm.group = miq_group if miq_group.present?
              end

              def vm_restore_retirement(source_vm, destination_vm)
                retirement_datetime = source_vm.retires_on
                retirement_warn = source_vm.retirement_warn
                destination_vm.retires_on = retirement_datetime if retirement_datetime.present?
                destination_vm.retirement_warn = retirement_warn if retirement_warn.present?
              end

              def main
                IDENTITY_ITEMS.each { |item| send("vm_restore_#{item}", source_vm, destination_vm) }
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
  ManageIQ::Automate::Transformation::Infrastructure::VM::Common::RestoreVmAttributes.new.main
end
