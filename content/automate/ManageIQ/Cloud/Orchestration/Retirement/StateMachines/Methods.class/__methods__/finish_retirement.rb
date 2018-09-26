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
                include ManageIQ::Automate::Cloud::Orchestration::Lifecycle::OrchestrationMixin

                def initialize(handle = $evm)
                  @handle = handle
                end

                def main
                  if (stack = get_stack(@handle))
                    stack.finish_retirement
                    @handle.create_notification(:type => :orchestration_stack_retired, :subject => stack)
                  end
                  get_service(@handle).try(:finish_retirement)
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
