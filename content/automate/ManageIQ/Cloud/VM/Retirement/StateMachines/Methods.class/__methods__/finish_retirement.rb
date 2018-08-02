#
# Description: This method marks the VM as retired
#
module ManageIQ
  module Automate
    module Cloud
      module VM
        module Retirement
          module StateMachines
            module Methods
              class FinishRetirement
                def initialize(handle = $evm)
                  @handle = handle
                end

                def main
                  vm = @handle.root['vm']
                  if vm
                    vm.finish_retirement
                    @handle.create_notification(:type => :vm_retired, :subject => vm)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Cloud::VM::Retirement::StateMachines::Methods::FinishRetirement.new.main
