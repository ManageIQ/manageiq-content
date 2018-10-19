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
                @task = ManageIQ::Automate::Transformation::Common::Utils.task(@handle)
                @source_vm = ManageIQ::Automate::Transformation::Common::Utils.source_vm(@handle)
                @destination_vm = ManageIQ::Automate::Transformation::Common::Utils.destination_vm(@handle)
              end

              def vm_restore_service
                if @source_vm.service
                  @destination_vm.add_to_service(@source_vm.service)
                  @source_vm.remove_from_service
                end
              end

              def vm_restore_tags
                @source_vm.tags.each do |tag|
                  @destination_vm.tag_assign(tag) unless tag =~ /^folder_path_/
                end
              end

              def vm_restore_custom_attributes
                @source_vm.custom_keys.each do |ca|
                  @destination_vm.custom_set(ca, @source_vm.custom_get(ca))
                end
              end

              def vm_restore_ownership
                owner = @source_vm.owner
                miq_group = @handle.vmdb(:miq_group).find_by(:id => @source_vm.miq_group_id)
                @destination_vm.owner = owner if owner.present?
                @destination_vm.group = miq_group if miq_group.present?
              end

              def vm_restore_retirement
                retirement_datetime = @source_vm.retires_on
                retirement_warn = @source_vm.retirement_warn
                @destination_vm.retires_on = retirement_datetime if retirement_datetime.present?
                @destination_vm.retirement_warn = retirement_warn if retirement_warn.present?
              end

              def main
                IDENTITY_ITEMS.each { |item| send("vm_restore_#{item}") }
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

ManageIQ::Automate::Transformation::Infrastructure::VM::Common::RestoreVmAttributes.new.main
