#
# Description: This method checks to see if the stack has been removed from the provider
#
module ManageIQ
  module Automate
    module Cloud
      module Orchestration
        module Retirement
          module StateMachines
            module Methods
              class CheckRemovedFromProvider

                def initialize(handle = $evm)
                  @handle = handle
                end

                def main
                  @handle.root['ae_result'] = 'ok'
                  stack = @handle.root['orchestration_stack']

                  if stack && @handle.get_state_var('stack_exists_in_provider')
                    begin
                      status, _reason = stack.normalized_live_status
                      if status == 'not_exist' || status == 'delete_complete'
                        @handle.set_state_var('stack_exists_in_provider', false)
                      else
                        @handle.root['ae_result'] = 'retry'
                        @handle.root['ae_retry_interval'] = '1.minute'
                      end
                    rescue => e
                      @handle.root['ae_result'] = 'error'
                      @handle.root['ae_reason'] = e.message
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

ManageIQ::Automate::Cloud::Orchestration::Retirement::StateMachines::Methods::CheckRemovedFromProvider.new.main
