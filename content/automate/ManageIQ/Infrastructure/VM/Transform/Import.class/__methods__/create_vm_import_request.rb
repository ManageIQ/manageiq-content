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

              def initialize_storage_map(provider_id)
                @storage_map = {}
                provider = @handle.vmdb(:ext_management_system, provider_id)
                return unless provider.present?
                provider.storages.each do |storage|
                  tag = storage_mapping_tag(storage)
                  next unless tag.present?
                  raise_error("Error, several storages are tagged with tag #{tag}") if @storage_map.key?(tag)
                  @storage_map[tag] = storage.id
                  @handle.log(:info, "Storage with tag #{tag} is mapped to target storage #{storage.name}")
                end
              end

              def main
                validate_root_args(%w(dialog_provider dialog_cluster dialog_sparse))
                if @handle.root['dialog_tag_category'].present? && @handle.root['dialog_tag_name'].present?
                  tag = "/#{@handle.root['dialog_tag_category']}/#{@handle.root['dialog_tag_name']}"
                  tagged_vms = @handle.vmdb('ManageIQ_Providers_Vmware_InfraManager_Vm')
                                      .find_tagged_with(:all => tag, :ns => '/managed')
                  initialize_storage_map(@handle.root['dialog_provider'])
                  tagged_vms.each do |vm|
                    target_storage_id = nil
                    if vm.storage.present?
                      tag = storage_mapping_tag(vm.storage)
                      raise_error("Error, cannot determine the target storage for storage #{vm.storage.name} without tag") unless tag.present?
                      target_storage_id = @storage_map[tag]
                      raise_error("Error, no target storage with tag #{tag}") unless target_storage_id.present?
                    end
                    create_request(vm, '', target_storage_id)
                  end
                else
                  validate_root_args(%w(vm dialog_storage))
                  create_request(@handle.root['vm'], @handle.root['dialog_name'], @handle.root['dialog_storage'])
                end
              end

              def raise_error(msg)
                @handle.log(:error, msg)
                raise msg
              end

              def validate_root_args(arg_names)
                arg_names.each do |name|
                  next if @handle.root[name].present?
                  raise_error("Error, required root attribute: #{name} not found")
                end
              end

              def storage_mapping_tag(storage)
                return nil unless storage.tags.present?

                tag = nil
                storage.tags.each do |t|
                  next unless t.start_with?("storage_mapping/")
                  raise_error("Error, storage #{storage.name} is tagged with several mapping tags") if tag.present?
                  tag = t
                end
                tag
              end

              def create_request(vm, target_name, storage_id)
                options = {
                  :namespace     => 'Infrastructure/VM/Transform/StateMachines',
                  :class_name    => 'VmImport',
                  :instance_name => 'default',
                  :message       => 'create',
                  :attrs         => {
                    'Vm::vm'      => vm.id,
                    'name'        => target_name.present? ? target_name : vm.name,
                    'provider_id' => @handle.root['dialog_provider'],
                    'cluster_id'  => @handle.root['dialog_cluster'],
                    'storage_id'  => storage_id,
                    'sparse'      => @handle.root['dialog_sparse'],
                    'drivers_iso' => @handle.root['dialog_install_drivers'] && @handle.root['dialog_drivers_iso']
                  },
                  :user_id       => @handle.root['user'].id
                }

                auto_approve = true
                @handle.execute('create_automation_request', options, @handle.root['user'].userid, auto_approve)
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Infrastructure::VM::Transform::Import::CreateVmImportRequest.new.main
