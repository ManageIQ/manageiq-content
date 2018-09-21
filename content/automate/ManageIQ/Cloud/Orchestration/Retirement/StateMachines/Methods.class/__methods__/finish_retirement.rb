#
# Description: This method marks the stack as retired
#
module ManageIQ
  module Automate
    module Cloud
      module Orchestration
        module Retirement
          module StateMachines
            module Methods
              class FinishRetirement
                def initialize(handle = $evm)
                  @handle = handle
                end

                def main
                  stack = @handle.root['orchestration_stack']
                  stack.finish_retirement if stack
                  @handle.create_notification(:type => :orchestration_stack_retired, :subject => stack) if stack
                end
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Cloud::Orchestration::Retirement::StateMachines::Methods::FinishRetirement.new.main
