module ManageIQ
  module Automate
    module Transformation
      module Common
        class AssessTransformationCleanup
          def initialize(handle = $evm)
            @handle = handle
            @debug = false
          end

          def main
            task = @handle.vmdb(:service_template_transformation_plan_task).find_by(:id => @handle.root['service_template_transformation_plan_task_id'])
            raise 'No task found. Exiting' if task.nil?
            @handle.log(:info, "Task: #{task.inspect}") if @debug

            destination_ems_id = task.get_option(:destination_ems_id)
            raise "'destination_ems_id' is not available" if destination_ems_id.blank?
            destination_ems = @handle.vmdb(:ext_management_system).find_by(:id => destination_ems_id)
            raise "Destination EMS with id '#{destination_ems_id}' doesn't exist." if destination_ems.blank?
            @handle.set_state_var(:destination_ems_type, destination_ems.emstype)
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
  ManageIQ::Automate::Transformation::Common::AssessTransformationCleanup.new.main
end
