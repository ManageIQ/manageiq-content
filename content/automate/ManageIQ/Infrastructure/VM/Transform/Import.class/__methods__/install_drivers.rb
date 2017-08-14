module ManageIQ
  module Automate
    module Infrastructure
      module VM
        module Transform
          module Import
            class InstallDrivers
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                os = @handle.root['vm'].operating_system
                is_windows = os.try(:product_name) =~ /windows/i
                checkbox_values = {
                  'value'     => is_windows ? 't' : 'f',
                  'read_only' => false,
                  'visible'   => true
                }
                checkbox_values.each do |key, value|
                  @handle.object[key] = value
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
  ManageIQ::Automate::Infrastructure::VM::Transform::Import::InstallDrivers.new.main
end
