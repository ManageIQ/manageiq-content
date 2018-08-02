module ManageIQ
  module Automate
    module Transformation
      module Infrastructure
        module VM
          module Common
            class RestoreVmAttributes
              IDENTITY_ITEMS = %w[service tags custom_attributes].freeze

              def initialize(handle = $evm)
                @handle = handle
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

              def main
                task = @handle.root['service_template_transformation_plan_task']
                source_vm = task.source
                destination_vm = @handle.vmdb(:vm).find_by(:id => task.get_option(:destination_vm_id))
                @handle.log(:info, "VM: #{destination_vm.name} [#{destination_vm.id}]")

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
