#
# Description: Given a Terraform Enterprise Run Id, check it's status
#

module ManageIQ
  module Automate
    module AutomationManagement
      module TerraformEnterprise
        module Operations
          module StateMachines
            module Job
              class WaitForCompletion
                STACK_CLASS = 'ManageIQ_Providers_AutomationManager_OrchestrationStack'.freeze
                def initialize(handle = $evm)
                  @handle = handle
                end

                def main
                  check_status(terraform_run)
                end

                private

                def check_status(run)
                  status, reason = run.normalized_live_status
                  case status
                  when 'transient'
                    @handle.root['ae_result'] = 'retry'
                    @handle.root['ae_retry_interval'] = 1.minute
                  when 'failed', 'create_canceled'
                    @handle.root['ae_result'] = 'error'
                    @handle.log(:error, "Job failed for #{run.id} Terraform Enterprise Run ID: #{run.ems_ref} reason #{reason}")
                    run.refresh_ems
                  when 'create_complete'
                    @handle.root['ae_result'] = 'ok'
                    run.refresh_ems
                  else
                    @handle.root['ae_result'] = 'error'
                    @handle.log(:error, "Job failed for #{run.id} Terraform Enterprise Run ID: #{run.ems_ref} Unknown status #{status} reason #{reason}")
                    run.refresh_ems
                  end
                end

                def terraform_run
                  run_id = @handle.get_state_var(:terraform_run_id)
                  if run_id.nil?
                    @handle.log(:error, 'Terraform Enterprise Run id not found')
                    exit(MIQ_ERROR)
                  end
                  fetch_run(run_id)
                end

                def fetch_run(run_id)
                  run = @handle.vmdb(STACK_CLASS).find(run_id)
                  if run.nil?
                    @handle.log(:error, "Terraform Enterprise Run with id: #{run_id} not found")
                    exit(MIQ_ERROR)
                  end
                  run
                end
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::AutomationManagement::TerraformEnterprise::Operations::StateMachines::Job::WaitForCompletion.new.main
