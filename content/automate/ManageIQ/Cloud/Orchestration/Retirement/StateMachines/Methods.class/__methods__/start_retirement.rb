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
                def initialize(handle = $evm)
                  @handle = handle
                end

                def main
                  log_info
                  start_retirement(stack)
                end

                private

                def stack
                  @handle.root["orchestration_stack"].tap do |stack|
                    raise 'OrchestrationStack Object not found' if stack.nil?
                  end
                end

                def stack_validation(stack)
                  if stack.retired?
                    raise 'Stack is already retired. Aborting current State Machine.'
                  end
                  if stack.retiring?
                    raise 'Stack is in the process of being retired. Aborting current State Machine.'
                  end
                end

                def log_info
                  @handle.log("info", "Listing Root Object Attributes:")
                  @handle.root.attributes.sort.each { |k, v| @handle.log("info", "\t#{k}: #{v}") }
                  @handle.log("info", "===========================================")
                end

                def start_retirement(stack)
                  stack_validation(stack)
                  @handle.log('info', "Stack before start_retirement: #{stack.inspect} ")
                  @handle.create_notification(:type => :vm_retiring, :subject => stack)

                  stack.start_retirement
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
