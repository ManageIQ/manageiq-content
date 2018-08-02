module ManageIQ
  module Automate
    module Infrastructure
      module VM
        module Transform
          module Import
            class ListInfraProviders
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                values_hash = {}
                values_hash[nil] = '-- select target infrastructure provider from list --'

                managers = @handle.vmdb('ManageIQ_Providers_Redhat_InfraManager').all.select(&:supports_vm_import?)
                managers.each do |manager|
                  values_hash[manager.id] = manager.name
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

ManageIQ::Automate::Infrastructure::VM::Transform::Import::ListInfraProviders.new.main
