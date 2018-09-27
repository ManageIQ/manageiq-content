module ManageIQ
  module Automate
    module Transformation
      module TransformationHosts
        module Common
          class KillVirtV2V
            def initialize(handle = $evm)
              @handle = handle
              @task = ManageIQ::Automate::Transformation::Common::Utils.task(@handle)
            end

            def task_virtv2v_state(transformation_host)
              require 'json'
              return if @task.get_option(:virtv2v_started_on).blank? || @task.get_option(:virtv2v_finished_on).present?
              return if @task.get_option(:virtv2v_wrapper).blank?
              result = ManageIQ::Automate::Transformation::TransformationHosts::Common::Utils.remote_command(@task, transformation_host, "cat '#{@task.get_option(:virtv2v_wrapper)['state_file']}'")
              return if !result[:success] || result[:stdout].empty?
              JSON.parse(result[:stdout])
            end

            def kill_virtv2v(transformation_host, pid)
              signal = 'KILL'
              unless @handle.get_state_var('virtv2v_graceful_kill')
                signal = 'TERM'
                @handle.set_state_var('virtv2v_graceful_kill', true)
                @handle.root['ae_result'] = 'retry'
                @handle.root['ae_retry_interval'] = '30.seconds'
              end
              ManageIQ::Automate::Transformation::TransformationHosts::Common::Utils.remote_command(@task, transformation_host, "kill -s #{signal} #{pid}")
            end

            def main
              transformation_host = @handle.vmdb(:host).find_by(:id => @task.get_option(:transformation_host_id))
              virtv2v_state = task_virtv2v_state(transformation_host)
              kill_virtv2v(transformation_host, virtv2v_state['pid']) if virtv2v_state.present?
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

ManageIQ::Automate::Transformation::TransformationHosts::Common::KillVirtV2V.new.main
