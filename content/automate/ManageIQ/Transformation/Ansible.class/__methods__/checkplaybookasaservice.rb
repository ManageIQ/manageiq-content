module ManageIQ
  module Automate
    module Transformation
      module Ansible
        class CheckPlaybookAsAService
          def initialize(handle = $evm)
            @handle = handle
          end

          def set_retry(message = nil, interval = '1.minutes')
            @handle.log(:info, message) if message.present?
            @handle.root['ae_result'] = 'retry'
            @handle.root['ae_retry_interval'] = interval
          end

          def main
            transformation_hook = @handle.inputs['transformation_hook']
            task = @handle.root['service_template_transformation_plan_task']
            service_request_id = task.get_option("#{transformation_hook}_ansible_playbook_service_request_id".to_sym)

            if service_request_id.present?
              service_request = @handle.vmdb(:miq_request).find_by(:id => service_request_id)

              playbooks_status = task.get_option(:playbooks) || {}
              playbooks_status[transformation_hook] = { :job_state => service_request.request_state }

              if service_request.request_state == 'finished'
                @handle.log(:info, "Ansible playbook service request (id: #{service_request_id}) is finished.")
                playbooks_status[transformation_hook][:job_status] = service_request.status
                playbooks_status[transformation_hook][:job_id] = service_request.miq_request_tasks.first.destination.service_resources.first.resource.id
                task.set_option(:playbooks, playbooks_status)
                if service_request.status == 'Error' && transformation_hook == 'pre'
                  raise "Ansible playbook has failed (hook=#{transformation_hook})"
                end
              else
                set_retry("Playbook for #{transformation_hook} migration is not finished. Retrying.", '15.seconds')
              end
              task.set_option(:playbooks, playbooks_status)
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

ManageIQ::Automate::Transformation::Ansible::CheckPlaybookAsAService.new.main
