module ManageIQ
  module Automate
    module Infrastructure
      module VM
        module Transform
          module Import
            class ListTagNames
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                multi_vm = @handle.root['vm'].nil?

                values_hash = {}
                values_hash[nil] = '<None>'

                if multi_vm
                  category_name = @handle.root['dialog_tag_category']
                  if category_name.present?
                    @handle.log(:info, "Selected tag category: #{category_name}")
                    category = @handle.vmdb(:classification).find_by_name(category_name)
                    unless category.nil?
                      category.entries.each do |tag|
                        values_hash[tag.name] = tag.description
                      end
                    end
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

ManageIQ::Automate::Infrastructure::VM::Transform::Import::ListTagNames.new.main
