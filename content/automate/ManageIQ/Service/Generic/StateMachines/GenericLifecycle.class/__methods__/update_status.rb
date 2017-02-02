#
# Description: This method updates the service status.
# Required inputs: status

module ManageIQ
  module Automate
    module Service
      module Generic
        module StateMachines
          module GenericLifecycle
            class UpdateStatus
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                @handle.log(:error, "Starting update_status")

                update_status
                @handle.log(:error, "Ending update_status")
              end

              private

              def update_status
                # Get status from input field status
                status = @handle.inputs['status']

                updated_message = String.new
                updated_message << "Server [#{@handle.root['miq_server'].name}] "
                updated_message << "Step [#{@handle.root['ae_state']}] "
                updated_message << "Status [#{status}] "
                updated_message << "Current Retry Number [#{@handle.root['ae_state_retries']}]"\
                                    if @handle.root['ae_result'] == 'retry'
                @handle.log(:error, "Status message: #{updated_message} ")
              end
            end
          end
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  ManageIQ::Automate::Service::Generic::StateMachines::GenericLifecycle::UpdateStatus.new.main
end
