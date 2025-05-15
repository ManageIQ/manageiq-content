#
# Description: This method examines the Terraform Enterprise Run provisioned
#

module ManageIQ
  module Automate
    module AutomationManagement
      module TerraformEnterprise
        module Service
          module Provisioning
            module StateMachines
              module Provision
                class PostProvision
                  def initialize(handle = $evm)
                    @handle = handle
                  end

                  def main
                    @handle.log("info", "Starting Terraform Enterprise Post-Provisioning")
                    stack = service.stack
                    raise "Run was not created" unless stack

                    # You can add logic to process the stack object in VMDB
                    # For example, dump all outputs from the stack
                    #
                    # dump_stack_outputs(stack)
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

                  def dump_stack_outputs(stack)
                    log_type = stack.status == 'failed' ? 'error' : 'info'
                    @handle.log(log_type, "Terraform Enterprise Run #{stack.name} standard output: #{stack.raw_stdout}") if stack.respond_to?(:raw_stdout)
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

ManageIQ::Automate::AutomationManagement::TerraformEnterprise::Service::Provisioning::StateMachines::Provision::PostProvision.new.main
