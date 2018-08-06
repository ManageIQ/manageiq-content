#
# Description: This method removes the stack from the VMDB database
#
module ManageIQ
  module Automate
    module Cloud
      module Orchestration
        module Retirement
          module StateMachines
            module Methods
              class DeleteFromVmdb

                def initialize(handle = $evm)
                  @handle = handle
                end

                def main
                  stack = @handle.root['orchestration_stack']

                  if stack && !@handle.get_state_var('stack_exists_in_provider')
                    @handle.log('info', "Removing stack <#{stack.name}> from VMDB")
                    stack.remove_from_vmdb
                    @handle.root['orchestration_stack'] = nil
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

ManageIQ::Automate::Cloud::Orchestration::Retirement::StateMachines::Methods::DeleteFromVmdb.new.main
