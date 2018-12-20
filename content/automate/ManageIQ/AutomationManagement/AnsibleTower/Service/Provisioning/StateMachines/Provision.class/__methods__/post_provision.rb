#
# Description: This method examines the AnsibleTower job provisioned
#

module ManageIQ
  module Automate
    module AutomationManagement
      module AnsibleTower
        module Service
          module Provisioning
            module StateMachines
              module Provision
                class PostProvision
                  def initialize(handle = $evm)
                    @handle = handle
                  end

                  def main
                    @handle.log("info", "Starting Ansible Tower Post-Provisioning")
                    job = service.job
                    raise "Job was not created" unless job

                    # You can add logic to process the job object in VMDB
                    # For example, dump all outputs from the job
                    #
                    # dump_job_outputs(job)
                  end

                  private

                  def task
                    @handle.root["service_template_provision_task"].tap do |task|
                      raise "service_template_provision_task not found" unless task
                    end
                  end

                  def service
                    task.destination.tap do |service|
                      raise "service is not of type AnsibleTower" unless service.respond_to?(:job_template)
                    end
                  end

                  def dump_job_outputs(job)
                    log_type = job.status == 'failed' ? 'error' : 'info'
                    @handle.log(log_type, "Ansible Tower Job #{job.name} standard output: #{job.raw_stdout}") if job.respond_to?(:raw_stdout)
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

ManageIQ::Automate::AutomationManagement::AnsibleTower::Service::Provisioning::StateMachines::Provision::PostProvision.new.main
