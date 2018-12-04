module ManageIQ
  module Automate
    module Transformation
      module Common
        class VMCheckTransformed
          def initialize(handle = $evm)
            @handle = handle
            @task = ManageIQ::Automate::Transformation::Common::Utils.task(@handle)
          end

          def set_retry
            @handle.root['ae_result'] = 'retry'
            @handle.root['ae_retry_server_affinity'] = true
            @handle.log(:info, "Disk transformation is not finished. Checking in #{@handle.root['ae_retry_interval']}")
          end

          def update_total_percentage
            virtv2v_disks = @task[:options][:virtv2v_disks]
            converted_disks = virtv2v_disks.reject { |d| d[:percent].zero? }
            message, percent = nil, nil
            if converted_disks.empty?
              percent = 1
              message = 'Disks transformation is initializing.'
            else
              percent = 0
              converted_disks.each { |disk| percent += (disk[:percent].to_f * disk[:weight].to_f / 100.0) }
              message = "Converting disk #{converted_disks.length} / #{virtv2v_disks.length} [#{percent.round(2)}%]."
            end
            [message, percent]
          end

          def main
            @task.get_conversion_state

            case @task.get_option(:virtv2v_status)
            when 'active'
              message, percent = update_total_percentage
              @handle.set_state_var(:ae_state_progress, 'message' => message, 'percent' => percent.round(2))
              set_retry
            when 'failed'
              @handle.set_state_var(:ae_state_progress, 'message' => 'Disks transformation failed.')
              raise "Disks transformation failed."
            when 'succeeded'
              @handle.set_state_var(:ae_state_progress, 'message' => 'Disks transformation succeeded.', 'percent' => 100)
            end
          rescue => e
            if @handle.root['ae_state_retries'] > 1
              @handle.set_state_var(:ae_state_progress, 'message' => e.message)
              raise
            else
              set_retry
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Transformation::Common::VMCheckTransformed.new.main
