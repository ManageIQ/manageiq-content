#
# Description: This method launches a Terraform Enterprise Run
#

module ManageIQ
  module Automate
    module AutomationManagement
      module TerraformEnterprise
        module Service
          module Provisioning
            module StateMachines
              module Provision
                class Provision
                  def initialize(handle = $evm)
                    @handle = handle
                  end

                  def main
                    @handle.log("info", "Starting Terraform Enterprise Provisioning")
                    run(task, service)
                  end

                  private

                  def task
                    @handle.root["service_template_provision_task"].tap do |task|
                      raise "service_template_provision_task not found" unless task
                    end
                  end

                  def service
                    task.destination.tap do |service|
                      raise "service is not of type TerraformEnterprise" unless service.respond_to?(:terraform_workspace)
                    end
                  end

                  def run(task, service)
                    stack = service.launch_stack
                    @handle.log("info", "Terraform Enterprise Run (#{stack.name}) with reference id (#{stack.ems_ref}) started.")
                  rescue => err
                    @handle.root['ae_result'] = 'error'
                    @handle.root['ae_reason'] = err.message
                    task.miq_request.user_message = err.message
                    @handle.log("error", "Template #{service.terraform_workspace.name} launching failed. Reason: #{err.message}")
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

ManageIQ::Automate::AutomationManagement::TerraformEnterprise::Service::Provisioning::StateMachines::Provision::Provision.new.main
