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

            def main
              require 'json'

              task = @handle.vmdb(:service_template_transformation_plan_task).find_by(:id => @handle.root['service_template_transformation_plan_task_id'])

              # Retrieve transformation host
              transformation_host = @handle.vmdb(:host).find_by(:id => task.get_option(:transformation_host_id))

              # Retrieve state of virt-v2v
              result = Transformation::TransformationHosts::Common::Utils.remote_command(task, transformation_host, "cat '#{task.get_option(:virtv2v_wrapper)['state_file']}'")
              if result[:success] && !result[:stdout].empty?
                virtv2v_state = JSON.parse(result[:stdout])
                @handle.log(:info, "VirtV2V State: #{virtv2v_state.inspect}")
                result = Transformation::TransformationHosts::Common::Utils.remote_command(task, transformation_host, "kill -9 #{virtv2v_state['pid']}")
                raise result[:stderr] unless result[:success]
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
end

if $PROGRAM_NAME == __FILE__
  ManageIQ::Automate::Transformation::TransformationHost::Common::VMCheckTransformed.new.main
end
