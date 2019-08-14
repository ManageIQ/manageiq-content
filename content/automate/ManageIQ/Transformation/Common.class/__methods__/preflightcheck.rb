module ManageIQ
  module Automate
    module Transformation
      module Common
        class PreflightCheck
          def initialize(handle = $evm)
            @handle = handle
            @task = ManageIQ::Automate::Transformation::Common::Utils.task(@handle)
          end

          def main
            @handle.log(:info, "PreflightCheck: task.state: #{@task.state}")
            if @task.state != 'migrate'
              @handle.root['ae_result'] = 'retry'
              @handle.root['ae_retry_server_affinity'] = true
              @handle.root['ae_retry_interval'] = 15.seconds
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Transformation::Common::PreflightCheck.new.main
