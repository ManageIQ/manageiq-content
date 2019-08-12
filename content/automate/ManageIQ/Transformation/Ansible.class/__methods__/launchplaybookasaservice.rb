module ManageIQ
  module Automate
    module Transformation
      module Ansible
        class LaunchPlaybookAsAService
          def initialize(handle = $evm)
            @handle = handle
            @task = ManageIQ::Automate::Transformation::Common::Utils.task
            @transformation_hook = @handle.inputs['transformation_hook']
          end

          def target_host
            case @transformation_hook
            when 'pre'
              @target_host ||= ManageIQ::Automate::Transformation::Common::Utils.source_vm
            when 'post'
              @target_host ||= ManageIQ::Automate::Transformation::Common::Utils.destination_vm
            end
          end

          def set_retry
            target_host.refresh
            @handle.root['ae_result'] = 'retry'
            @handle.root['ae_retry_interval'] = '15.seconds'
          end

          def ipaddress_available
            ipaddr = target_host.ipaddresses.first
            set_retry if ipaddr.nil?
            ipaddr.present?
          end

          def main
            return if @transformation_hook == '_'

            service_template = @task.send("#{@transformation_hook}_ansible_playbook_service_template")
            return if service_template.nil?
            return if target_host.blank?
            return unless ipaddress_available

            service_dialog_options = {
              :credential => service_template.config_info[:provision][:credential_id],
              :hosts      => target_host.ipaddresses.first
            }
            service_request = @handle.execute(:create_service_provision_request, service_template, service_dialog_options)
            @task.set_option("#{@transformation_hook}_ansible_playbook_service_request_id".to_sym, service_request.id)
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
