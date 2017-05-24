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
                values_hash = {}
                values_hash[nil] = '-- select storage from list --'

                provider_id = @handle.root['dialog_provider']
                @handle.log(:info, "Selected provider: #{provider_id}")
                if provider_id.present? && provider_id != '!'
                  provider = @handle.vmdb(:ext_management_system, provider_id)
                  if provider.nil?
                    values_hash[nil] = 'None'
                  else
                    provider.storages.each do |storage|
                      values_hash[storage.id] = storage.name
                    end
                  end
                end
                list_values = {
                  'sort_by'   => :description,
                  'data_type' => :string,
                  'required'  => true,
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

if __FILE__ == $PROGRAM_NAME
  ManageIQ::Automate::Infrastructure::VM::Transform::Import::ListStorages.new.main
end
