module ManageIQ
  module Automate
    module Transformation
      module Common
        class VMTransform
          def initialize(handle = $evm)
            @debug = false
            @handle = handle
            @task = ManageIQ::Automate::Transformation::Common::Utils.task(@handle)
          end

          def main
            # WARNING: Enable at your own risk, as it may lead to sensitive data leak
            # @handle.log(:info, "JSON Input:\n#{JSON.pretty_generate(@task.conversion_options)}") if @debug

            @task.run_conversion
          rescue => e
            @handle.set_state_var(:ae_state_progress, 'message' => e.message)
            raise
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Transformation::Common::VMTransform.new.main
