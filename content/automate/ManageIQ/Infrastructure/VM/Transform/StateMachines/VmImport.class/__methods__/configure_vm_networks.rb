#
# Description: This method initiates post-import configuration of VM network interfaces.
#

module ManageIQ
  module Automate
    module Infrastructure
      module VM
        module Transform
          module StateMachines
            class ConfigureVmNetworks
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                validate_root_args %w(provider_id)

                provider = @handle.vmdb(:ext_management_system, @handle.root['provider_id'])
                vm_id = @handle.get_state_var('imported_vm_id')
                @handle.log(:info, "Configuring VM ID: #{vm_id} Networks")
                provider.submit_configure_imported_vm_networks(@handle.root['user'].userid, vm_id)
              end

              def validate_root_args(arg_names)
                arg_names.each do |name|
                  next if @handle.root[name].present?
                  msg = "Error, required root attribute: #{name} not found"
                  @handle.log(:error, msg)
                  raise msg
                end
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Infrastructure::VM::Transform::StateMachines::ConfigureVmNetworks.new.main
