#
# Description: This method removes the Instance from the provider
#
# ManageIQ/Cloud/VM/Retirement/StateMachines/Methods.class/__methods__/remove_from_provider.rb
module ManageIQ
  module Automate
    module Cloud
      module VM
        module Retirement
          module StateMachines
            module Methods
              class RemoveFromProvider
                def initialize(handle = $evm)
                  @handle = handle
                end

                def main
                  # Get vm from root object
                  @vm = @handle.root['vm']

                  @handle.set_state_var('vm_removed_from_provider', false)
                  @ems = @vm.ext_management_system if @vm

                  if @vm && @ems
                    remove_vm
                  else
                    @handle.log('info', "Skipping remove from provider for Instance:<#{@vm.try(:name)}> on provider:<#{@ems.try(:name)}>")
                  end
                end

                private

                def remove_vm
                  category = "lifecycle"
                  tag = "retire_full"

                  case @handle.inputs['removal_type'].try(:downcase)
                  when "remove_from_disk"
                    remove_from_disk if @vm.miq_provision || @vm.tagged_with?(category, tag)
                  when "unregister"
                    unregister
                  else
                    @handle.log('info', "Unknown retirement type for VM:<#{@vm.name}> from provider:<#{@ems.name}>")
                    raise 'Unknown retirement type'
                  end
                end

                def remove_from_disk
                  @handle.log('info', "Removing Instance:<#{@vm.name}> from provider:<#{@ems.name}>")
                  @vm.remove_from_disk(false)
                  @handle.set_state_var('vm_removed_from_provider', true)
                end

                def unregister
                  @handle.log('info', "Unregistering Instance:<#{@vm.name}> from provider:<#{@ems.name}>")
                  @vm.unregister
                  @handle.set_state_var('vm_removed_from_provider', true)
                end
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Cloud::VM::Retirement::StateMachines::Methods::RemoveFromProvider.new.main
