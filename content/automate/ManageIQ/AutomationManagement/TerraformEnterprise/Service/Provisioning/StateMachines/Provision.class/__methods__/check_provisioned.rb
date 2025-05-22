#
# Description: This method checks to see if the workspace has been provisioned
# and refresh the run when it completes at the provider
#

module ManageIQ
  module Automate
    module AutomationManagement
      module TerraformEnterprise
        module Service
          module Provisioning
            module StateMachines
              module Provision
                class CheckProvisioned
                  def initialize(handle = $evm)
                    @handle = handle
                  end

                  def main
                    @handle.log("info", "Checking status of Terraform Enterprise Provisioning")
                    check_provisioned(task, service)
                  end

                  private

                  def check_provisioned(task, service)
                    # check whether the Terraform Enterprise Stack completed
                    stack = service.stack

                    if stack.nil?
                      @handle.root['ae_result'] = 'error'
                      @handle.root['ae_reason'] = 'run was not created'
                    else
                      check_status(stack)
                    end

                    unless @handle.root['ae_result'] == 'retry'
                      @handle.log("info", "Terraform Enterprise Run finished. Status: #{@handle.root['ae_result']}, reason: #{@handle.root['ae_reason']}")
                      @handle.log('error', 'Please examine stack console output for more details') if @handle.root['ae_result'] == 'error'

                      stack.refresh
                      task.miq_request.user_message = @handle.root['ae_reason'] unless @handle.root['ae_reason'].blank?
                    end
                  end

                  def check_status(stack)
                    status, reason = stack.normalized_live_status
                    case status.downcase
                    when 'create_complete'
                      @handle.root['ae_result'] = 'ok'
                    when /failed$/, /canceled$/
                      @handle.root['ae_result'] = 'error'
                      @handle.root['ae_reason'] = reason
                      @handle.log('error', "Terraform Enterprise Run #{stack.name} standard output: #{stack.raw_stdout}") if stack.respond_to?(:raw_stdout)
                    else
                      # run not done yet in provider, queue a refresh and check again
                      @handle.root['ae_result']         = 'retry'
                      @handle.root['ae_retry_interval'] = '1.minute'
                      stack.refresh
                    end
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
                end
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::AutomationManagement::TerraformEnterprise::Service::Provisioning::StateMachines::Provision::CheckProvisioned.new.main
