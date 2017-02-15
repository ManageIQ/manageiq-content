#
# Description: This class updates the provisioning status and retries
# from the desired step.
# Required inputs: status
# Optional inputs: max_retries, error_to_catch, restart_from_state
#
module ManageIQ
  module Automate
    module Service
      module Generic
        module StateMachines
          module VMProvision_VM
            class RetryState
              DEFAULT_MAX_RETRIES = 3
              DEFAULT_ERROR_TO_CATCH = "An error occurred while provisioning Instance".freeze
              DEFAULT_RESTART_FROM_STATE = "Placement".freeze

              def initialize(handle = $evm)
                @handle = handle
                @prov = @handle.root['miq_provision']
                @max_retries = @handle.inputs['max_retries'] || DEFAULT_MAX_RETRIES
                @restart_from_state = @handle.inputs['restart_from_state'] || DEFAULT_RESTART_FROM_STATE
                @error_to_catch = @handle.inputs['error_to_catch'] || DEFAULT_ERROR_TO_CATCH
                @retry_number = if @handle.state_var_exist?(:state_retries)
                                  @handle.get_state_var(:state_retries)
                                else
                                  0
                                end
              end

              def main
                @handle.log("info", "Starting retry_state")
                retry_state
                @handle.log("info", "Ending retry_state")
              end

              private

              def update_status_message
                status = @handle.inputs['status']
                updated_message  = "[#{@handle.root['miq_server'].name}] "
                updated_message += "VM [#{@prov.get_option(:vm_target_name)}] "
                updated_message += "Step [#{@handle.root['ae_state']}] "
                updated_message += "Status [#{status}] "
                updated_message += "Message [#{@prov.message}] "
                if @handle.root['ae_result'] == 'restart'
                  updated_message += "Restarting from #{@restart_from_state} step"
                end
                @prov.miq_request.user_message = updated_message
                @prov.message = status
              end

              def retry_state
                if @prov.message.include?(@error_to_catch) && (@retry_number < @max_retries)
                  @handle.root['ae_result'] = 'restart'
                  @handle.root['ae_next_state'] = @restart_from_state
                  @handle.log("info", "Provisioning #{@prov.get_option(:vm_target_name)} failed, retrying #{@restart_from_state}.")
                  @handle.set_state_var(:state_retries, @retry_number + 1)
                end
                update_status_message
              end
            end
          end
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  ManageIQ::Automate::Service::Generic::StateMachines::VMProvision_VM::RetryState.new.main
end
