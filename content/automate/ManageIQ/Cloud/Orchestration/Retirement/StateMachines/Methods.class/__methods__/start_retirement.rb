#
# Description: This method sets the retirement_state to retiring
#
module ManageIQ
  module Automate
    module Cloud
      module Orchestration
        module Retirement
          module StateMachines
            module Methods
              class StartRetirement
                include ManageIQ::Automate::Cloud::Orchestration::Lifecycle::OrchestrationMixin

                def initialize(handle = $evm)
                  @handle = handle
                end

                def main
                  stack = get_stack(@handle)

                  if stack.nil?
                    @handle.log('error', "OrchestrationStack Object not found")
                    exit MIQ_ABORT
                  end

                  if stack.retired?
                    @handle.log('error', "Stack is already retired. Aborting current State Machine.")
                    exit MIQ_ABORT
                  end

                  if stack.retiring?
                    @handle.log('error', "Stack is in the process of being retired. Aborting current State Machine.")
                    exit MIQ_ABORT
                  end

                  @handle.log('info', "Stack before start_retirement: #{stack.inspect} ")
                  @handle.create_notification(:type => :vm_retiring, :subject => stack)

                  stack.start_retirement
                  get_service(@handle).try(:start_retirement)
                end
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Cloud::Orchestration::Retirement::StateMachines::Methods::StartRetirement.new.main
