module ManageIQ
  module Automate
    module Transformation
      module Common
        class AcquireTransformationHost
          def initialize(handle = $evm)
            @handle = handle
            @task = ManageIQ::Automate::Transformation::Common::Utils.task(@handle)
          end

          def main
            if @task.conversion_host.nil?
              @handle.root['ae_result'] = 'retry'
              @handle.root['ae_retry_server_affinity'] = true
              @handle.root['ae_retry_interval'] = 15.seconds
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

ManageIQ::Automate::Transformation::Common::AcquireTransformationHost.new.main
