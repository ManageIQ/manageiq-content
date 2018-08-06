module ManageIQ
  module Automate
    module Infrastructure
      module VM
        module Transform
          module Import
            class ShowName
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                multi_vm = @handle.root['vm'].nil?

                input_values = {
                  'data_type' => :string,
                  'required'  => false,
                  'visible'   => !multi_vm,
                }
                input_values.each { |key, value| @handle.object[key] = value }
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Infrastructure::VM::Transform::Import::ShowName.new.main
