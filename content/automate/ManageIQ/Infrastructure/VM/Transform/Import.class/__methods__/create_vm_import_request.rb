#
# Description: This method initiates VM import to given infra provider
#

module ManageIQ
  module Automate
    module Infrastructure
      module VM
        module Transform
          module Import
            class CreateVmImportRequest
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                validate_root_args %w(vm dialog_name dialog_provider dialog_cluster dialog_storage dialog_sparse)

                options = {
                  :namespace     => 'Infrastructure/VM/Transform/StateMachines',
                  :class_name    => 'VmImport',
                  :instance_name => 'default',
                  :message       => 'create',
                  :attrs         => {
                    'Vm::vm'      => @handle.root['vm'].id,
                    'name'        => @handle.root['dialog_name'],
                    'provider_id' => @handle.root['dialog_provider'],
                    'cluster_id'  => @handle.root['dialog_cluster'],
                    'storage_id'  => @handle.root['dialog_storage'],
                    'sparse'      => @handle.root['dialog_sparse'],
                    'drivers_iso' => @handle.root['dialog_install_drivers'] && @handle.root['dialog_drivers_iso']
                  },
                  :user_id       => @handle.root['user'].id
                }

                auto_approve = true
                @handle.execute('create_automation_request', options, @handle.root['user'].userid, auto_approve)
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

if __FILE__ == $PROGRAM_NAME
  ManageIQ::Automate::Infrastructure::VM::Transform::Import::CreateVmImportRequest.new.main
end
