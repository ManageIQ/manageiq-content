module ManageIQ
  module Automate
    module Transformation
      module Ansible
        class LaunchPlaybookAsAService
          def initialize(handle = $evm)
            @handle = handle
          end

          def target_host(task, transformation_hook)
            target_host = nil
            case transformation_hook
            when 'pre'
              target_host = task.source
            when 'post'
              target_host = @handle.vmdb(:vm).find_by(:id => task.get_option(:destination_vm_id))
            end
            target_host
          end

          def main
            task = @handle.root['service_template_transformation_plan_task']
            transformation_hook = @handle.inputs['transformation_hook']

            return if transformation_hook == '_'
            service_template = task.send("#{transformation_hook}_ansible_playbook_service_template")
            return if service_template.nil?
            target_host = target_host(task, transformation_hook)
            return if target_host.blank?
            service_dialog_options = { :hosts => target_host.ipaddresses.first }
            service_request = @handle.execute(:create_service_provision_request, service_template, service_dialog_options)
            task.set_option("#{transformation_hook}_ansible_playbook_service_request_id".to_sym, service_request.id)
          rescue => e
            @handle.set_state_var(:ae_state_progress, 'message' => e.message)
            raise
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Transformation::Ansible::LaunchPlaybookAsAService.new.main
