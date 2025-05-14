#
# Description: This method prepares arguments and parameters for a workspace
#
module ManageIQ
  module Automate
    module AutomationManagement
      module TerraformEnterprise
        module Service
          module Provisioning
            module StateMachines
              module Provision
                class Preprovision
                  def initialize(handle = $evm)
                    @handle = handle
                  end

                  def main
                    @handle.log("info", "Starting Terraform Enterprise Pre-Provisioning")
                    examine_request(service)
                    # modify_stack_options(service)
                  end

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

                  # Through service you can examine the workspace, configuration manager (i.e., provider)
                  # and options to start a run
                  def examine_request(service)
                    @handle.log("info", "manager = #{service.configuration_manager.name}")
                    @handle.log("info", "template = #{service.terraform_workspace.name}")

                    # Caution: stack options may contain passwords.
                    # @handle.log("info", "stack options = #{service.stack_options.inspect}")
                  end

                  # You can also override stack options through service
                  def modify_stack_options(service)
                    # Example how to programmatically modify stack options:
                    stack_options = service.stack_options
                    stack_options[:limit] = 'someHost'
                    stack_options[:extra_vars]['flavor'] = 'm1.small'

                    # Important: set stack_options
                    service.stack_options = stack_options
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

ManageIQ::Automate::AutomationManagement::TerraformEnterprise::Service::Provisioning::StateMachines::Provision::Preprovision.new.main
