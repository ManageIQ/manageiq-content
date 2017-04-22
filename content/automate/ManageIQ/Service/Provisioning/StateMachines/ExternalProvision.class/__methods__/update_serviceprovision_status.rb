#
# Description: This method updates the service provision status.
# Required inputs: status

module ManageIQ
  module Automate
    module Service
      module Provisioning
        module StateMachines
          module ExternalProvision
            class UpdateServiceProvisionStatus
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                prov = @handle.root["service_template_provision_task"]
                unless prov
                  $evm.log(:error, "Service Template Provision Task not provided")
                  @handle.root['ae_result'] = 'error'
                  return
                end
                update_status(prov)
              end

              private

              def update_status(prov)
                # Get status from input field status
                status = @handle.inputs['status']

                # Update Status Message
                updated_message = String.new
                updated_message << "Server [#{@handle.root['miq_server'].name}] "
                updated_message << "Service [#{prov.destination.name}] "
                updated_message << "Step [#{@handle.root['ae_state']}] "
                updated_message << "Status [#{status}] "
                updated_message << "Message [#{prov.message}] "
                updated_message << "Current Retry Number [#{@handle.root['ae_state_retries']}]"\
                                    if @handle.root['ae_result'] == 'retry'
                prov.miq_request.user_message = updated_message
                prov.message = status
              end
            end
          end
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  ManageIQ::Automate::Service::Provisioning::StateMachines::ExternalProvision::UpdateServiceProvisionStatus.new.main
end
