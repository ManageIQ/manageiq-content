#
# Description: This method initiates VM import to given infra provider
#

module ManageIQ
  module Automate
    module Infrastructure
      module VM
        module Transform
          module StateMachines
            class SubmitVmImport
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                validate_root_args %w(vm name cluster_id storage_id sparse)

                provider = @handle.vmdb(:ext_management_system, @handle.root['provider_id'])
                @handle.log(:info, 'Submitting Import')
                new_ems_ref = provider.submit_import_vm(
                  @handle.root['user'].userid,
                  @handle.root['vm'].id,
                  :name        => @handle.root['name'],
                  :cluster_id  => @handle.root['cluster_id'],
                  :storage_id  => @handle.root['storage_id'],
                  :sparse      => @handle.root['sparse'],
                  :drivers_iso => @handle.root['drivers_iso']
                )
                @handle.log(:info, "New Ems Ref is #{new_ems_ref}")
                @handle.set_state_var('new_ems_ref', new_ems_ref)
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

ManageIQ::Automate::Infrastructure::VM::Transform::StateMachines::SubmitVmImport.new.main
