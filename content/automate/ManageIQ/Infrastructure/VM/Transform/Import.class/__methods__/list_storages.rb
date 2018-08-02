module ManageIQ
  module Automate
    module Infrastructure
      module VM
        module Transform
          module Import
            class ListStorages
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                multi_vm = @handle.root['vm'].nil?

                values_hash = {}
                values_hash[nil] = '-- select storage from list --'

                unless multi_vm
                  provider_id = @handle.root['dialog_provider']
                  if provider_id.present? && provider_id != '!'
                    provider = @handle.vmdb(:ext_management_system, provider_id)
                    if provider.nil?
                      values_hash[nil] = 'None'
                    else
                      provider.storages.each do |storage|
                        values_hash[storage.id] = storage.name if storage.storage_domain_type == "data"
                      end
                    end
                  end
                end
                list_values = {
                  'sort_by'   => :description,
                  'data_type' => :string,
                  'required'  => !multi_vm,
                  'visible'   => !multi_vm,
                  'values'    => values_hash
                }
                list_values.each { |key, value| @handle.object[key] = value }
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Infrastructure::VM::Transform::Import::ListStorages.new.main
