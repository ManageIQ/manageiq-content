module ManageIQ
  module Automate
    module Transformation
      module Common
        class AcquireTransformationHost
          def initialize(handle = $evm)
            @handle = handle
          end

          def main
            factory_config = @handle.get_state_var(:factory_config)
            raise "No factory config found. Aborting." if factory_config.nil?

            task = @handle.root['service_template_transformation_plan_task']
            @handle.log(:info, "Task: #{task.inspect}")

            transformation_host_type, transformation_host, transformation_method = ManageIQ::Automate::Transformation::TransformationHosts::Common::Utils.get_transformation_host(task, factory_config)
            if transformation_host.nil?
              @handle.log(:info, "No transformation host available. Retrying.")
              @handle.root['ae_result'] = 'retry'
              @handle.root['ae_retry_server_affinity'] = true
              @handle.root['ae_retry_interval'] = $evm.object['check_convert_interval'] || '1.minutes'
            else
              @handle.log(:info, "Transformation Host: #{transformation_host.name}.")
              task.set_option(:transformation_host_id, transformation_host.id)
              task.set_option(:transformation_host_name, transformation_host.name)
              task.set_option(:transformation_host_type, transformation_host_type)
              task.set_option(:transformation_method, transformation_method)
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
  ManageIQ::Automate::Transformation::Common::AcquireTransformationHost.new.main
end
