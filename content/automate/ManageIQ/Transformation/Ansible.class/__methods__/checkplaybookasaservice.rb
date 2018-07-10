module ManageIQ
  module Automate
    module Transformation
      module Ansible
        class CheckPlaybookAsAService
          def initialize(handle = $evm)
            @handle = handle
          end

          def set_retry(message, interval = '1.minutes')
            @handle.log(:info, "#{message}. Retrying.")
            @handle.root['ae_result'] = 'retry'
            @handle.root['ae_retry_interval'] = interval
          end

          def job_status(job)
            { :job_id => job.id, :job_status => job.status }
          end

          def set_ansible_job(task, service_request, transformation_hook)
            job = nil
            service_request_task = service_request.miq_request_tasks.first
            unless service_request_task.nil?
              stack = service_request_task.destination.service_resources.first
              job = stack.resource unless stack.nil?
            end
            playbooks_status = task.get_option(:playbooks) || {}

            if playbooks_status[transformation_hook].nil?
              if job.nil?
                set_retry('Ansible job has not started yet.', '15.seconds')
              else
                playbooks_status[transformation_hook] = job_status(job)
                task.set_option(:playbooks, playbooks_status)
              end
            end
          end

          def main
            transformation_hook = @handle.inputs['transformation_hook']

            task = @handle.root['service_template_transformation_plan_task']
            service_request_id = task.get_option("#{transformation_hook}_ansible_playbook_service_request_id")
            service_request = @handle.vmdb(:miq_request).find_by(:id => service_request_id)

            set_ansible_job(task, service_request, transformation_hook)

            if service_request.request_state == 'finished'
              @handle.log(:info, "Ansible playbook service request (id: #{service_request_id}) is finished.")
              if transformation_hook == 'pre' && service_request.status == 'Error'
                raise "Ansible playbook has failed (hook=#{transformation_hook})"
              end
            else
              set_retry('Service request is not finished yet.', '15.seconds')
            end
          rescue => e
            @handle.set_state_var(:ae_state_progress, 'message' => e.message)
            raise
          end
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  ManageIQ::Automate::Transformation::Ansible::CheckPlaybookAsAService.new.main
end
