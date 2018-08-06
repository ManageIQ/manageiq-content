#
# Description: This method updates the service provision status.
# Required inputs: status

module ManageIQ
  module Automate
    module AutomationManagement
      module AnsibleTower
        module Service
          module Provisioning
            module StateMachines
              class UpdateServiceProvisionStatus
                def initialize(handle = $evm)
                  @handle = handle
                end

                def main
                  prov = @handle.root['service_template_provision_task']

                  if prov.nil?
                    @handle.log(:error, "Service Template Provision Task not provided")
                    raise "Service Template Provision Task not provided"
                  end

                  updated_message = update_status_message(prov, @handle.inputs['status'])

                  if @handle.root['ae_result'] == "error"
                    @handle.create_notification(:level   => "error",
                                                :subject => prov.miq_request,
                                                :message => "Instance Provision Error: #{updated_message}")
                    @handle.log(:error, "Instance Provision Error: #{updated_message}")
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

ManageIQ::Automate::AutomationManagement::AnsibleTower::Service::Provisioning::StateMachines::UpdateServiceProvisionStatus.new.main
