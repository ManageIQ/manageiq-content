module ManageIQ
  module Automate
    module Transformation
      module Common
        class KillVirtV2V
          def initialize(handle = $evm)
            @handle = handle
            @task = ManageIQ::Automate::Transformation::Common::Utils.task(@handle)
          end

          def task_virtv2v_state
            return if @task.get_option(:virtv2v_started_on).blank? || @task.get_option(:virtv2v_finished_on).present? || @task.get_option(:virtv2v_wrapper).blank?
            @task.get_conversion_state
          end

          def kill_signal
            if @handle.get_state_var('virtv2v_graceful_kill')
              'KILL'
            else
              @handle.set_state_var('virtv2v_graceful_kill', true)
              @handle.root['ae_result'] = 'retry'
              @handle.root['ae_retry_interval'] = '30.seconds'
              'TERM'
            end
          end

          def main
            @task.kill_virtv2v(kill_signal) unless task_virtv2v_state.nil?
          rescue => e
            @handle.set_state_var(:ae_state_progress, 'message' => e.message)
            raise
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Transformation::Common::KillVirtV2V.new.main
