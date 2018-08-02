module ManageIQ
  module Automate
    module Infrastructure
      module VM
        module Transform
          module Import
            class ListClusters
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                values_hash = {}
                values_hash[nil] = '-- select cluster from list --'

                provider_id = @handle.root['dialog_provider']
                if provider_id.present? && provider_id != '!'
                  provider = @handle.vmdb(:ext_management_system, provider_id)
                  if provider.nil?
                    values_hash[nil] = 'None'
                  else
                    provider.ems_clusters.each do |cluster|
                      values_hash[cluster.id] = cluster.name
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

ManageIQ::Automate::Infrastructure::VM::Transform::Import::ListClusters.new.main
