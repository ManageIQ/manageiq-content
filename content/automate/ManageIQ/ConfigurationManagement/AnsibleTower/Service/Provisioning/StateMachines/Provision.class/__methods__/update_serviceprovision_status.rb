#
# Description: This method updates the service provision status.
# Required inputs: status
#
module ManageIQ
  module Automate
    module ConfigurationManagement
      module AnsibleTower
        module Service
          module Provisioning
            module StateMachines
              class UpdateServiceProvisionStatus
                def initialize(handle = $evm)
                  @handle = handle
                end

                def main
                  @handle.log("warn", "[DEPRECATION] This method will be deprecated. Please use similarly named method from AutomationManagement namespace.")
                  prov = @handle.root['service_template_provision_task']

                  if prov.nil?
                    @handle.log(:error, "Service Template Provision Task not provided")
                    raise "Service Template Provision Task not provided"
                  end

                  updated_message = update_status_message(prov, @handle.inputs['status'])

                  if @handle.root['ae_result'] == 'error'
                    @handle.create_notification(:level   => 'error',
                                                :subject => prov.miq_request,
                                                :message => "Ansible Tower Provision Error: #{updated_message}")
                    @handle.log(:error, "Ansible Tower Provision Error: #{updated_message}")
                  end
                end

                private

                def update_status_message(prov, status)
                  updated_message  = "Server [#{@handle.root['miq_server'].name}] "
                  updated_message += "Service [#{prov.destination.name}] "
                  updated_message += "Step [#{@handle.root['ae_state']}] "
                  updated_message += "Status [#{status}] "
                  updated_message += "Message [#{prov.message}] "
                  updated_message += "Current Retry Number [#{@handle.root['ae_state_retries']}]"\
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
end

if __FILE__ == $PROGRAM_NAME
  ManageIQ::Automate::ConfigurationManagement::AnsibleTower::Service::
    Provisioning::StateMachines::UpdateServiceProvisionStatus.new.main
end
