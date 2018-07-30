module ManageIQ
  module Automate
    module Transformation
      module TransformationHost
        module Common
          class VMCheckTransformed
            def initialize(handle = $evm)
              @debug = true
              @handle = handle
            end

            def task_virtv2v_state(task, transformation_host)
              require 'json'
              return if task.get_option(:virtv2v_started_on).blank? || task.get_option(:virtv2v_finished_on).present?
              return if task.get_option(:virtv2v_wrapper).blank?
              result = Transformation::TransformationHosts::Common::Utils.remote_command(task, transformation_host, "cat '#{task.get_option(:virtv2v_wrapper)['state_file']}'")
              return if !result[:success] || result[:stdout].empty?
              JSON.parse(result[:stdout])
            end

            def main
              task = @handle.vmdb(:service_template_transformation_plan_task).find_by(:id => @handle.root['service_template_transformation_plan_task_id'])
              transformation_host = @handle.vmdb(:host).find_by(:id => task.get_option(:transformation_host_id))
              virtv2v_state = task_virtv2v_state(task, transformation_host)
              @handle.log(:info, "VirtV2V State: #{virtv2v_state.inspect}")
              Transformation::TransformationHosts::Common::Utils.remote_command(task, transformation_host, "kill -9 #{virtv2v_state['pid']}") if virtv2v_state.present?
            rescue => e
              @handle.set_state_var(:ae_state_progress, 'message' => e.message)
              raise
            end
          end
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  ManageIQ::Automate::Transformation::TransformationHost::Common::VMCheckTransformed.new.main
end
