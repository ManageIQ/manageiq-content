module ManageIQ
  module Automate
    module Transformation
      module Common
        class WaitForHandover
          def initialize(handle = $evm)
            @handle = handle
            @task = ManageIQ::Automate::Transformation::Common::Utils.task(@handle)
          end

          def main
            @handle.log(:info, "WaitForHandover: task.state: #{@task.state} - task.options.workflow_runner: #{@task.get_option(:workflow_runner)}")
            if @task.state != 'migrate' || @task.get_option(:workflow_runner) != 'automate'
              @handle.root['ae_result'] = 'retry'
              @handle.root['ae_retry_server_affinity'] = true
              @handle.root['ae_retry_interval'] = 15.seconds
            elsif @task.get_option(:progress)[:status] == "error"
              raise 'Migration failed'
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Transformation::Common::WaitForHandover.new.main
