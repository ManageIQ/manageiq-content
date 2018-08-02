module ManageIQ
  module Automate
    module Infrastructure
      module VM
        module Transform
          module Import
            class ListTagCategories
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                multi_vm = @handle.root['vm'].nil?

                values_hash = {}
                values_hash[nil] = '<None>'

                if multi_vm
                  categories = @handle.vmdb(:classification).categories
                  categories.each do |category|
                    values_hash[category.name] = category.description
                  end
                end
                list_values = {
                  'sort_by'   => :description,
                  'data_type' => :string,
                  'required'  => false,
                  'visible'   => multi_vm,
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

ManageIQ::Automate::Infrastructure::VM::Transform::Import::ListTagCategories.new.main
