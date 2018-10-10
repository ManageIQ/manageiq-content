#
# Description: This method removes the stack from the provider
#
module ManageIQ
  module Automate
    module Cloud
      module Orchestration
        module Retirement
          module StateMachines
            module Methods
              class RemoveFromProviders
                include ManageIQ::Automate::Cloud::Orchestration::Lifecycle::OrchestrationMixin

                def initialize(handle = $evm)
                  @handle = handle
                end

                def main
                  if (stack = get_stack(@handle))
                    ems = stack.ext_management_system
                    if stack.raw_exists?
                      @handle.log('info', "Removing stack:<#{stack.name}> from provider:<#{ems.try(:name)}>")
                      stack.raw_delete_stack
                      @handle.set_state_var('stack_exists_in_provider', true)
                    else
                      @handle.log('info', "Stack <#{stack.name}> no longer exists in provider:<#{ems.try(:name)}>")
                      @handle.set_state_var('stack_exists_in_provider', false)
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
end

ManageIQ::Automate::Cloud::Orchestration::Retirement::StateMachines::Methods::RemoveFromProviders.new.main
