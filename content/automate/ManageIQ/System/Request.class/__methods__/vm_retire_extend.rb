#
# Description: This method is used to add 14 days to retirement date when target
# VM has a retires_on value and is not already retired
#

module ManageIQ
  module Automate
    module System
      module Request
        class VmRetireExtend
          DEFAULT_EXTENSION_DAYS = 14
          def initialize(handle = $evm)
            @handle = handle
          end

          def main
            validate
            extend_retirement
          end

          private

          def vm
            @vm ||= @handle.root["vm"].tap do |vm|
              if vm.nil?
                @handle.log(:error, 'vm is nil')
                raise 'ERROR - vm object not passed in'
              end
            end
          end

          def validate
            if vm.retires_on.blank?
              raise "ERROR - VM #{vm.name} has no retirement date - extension bypassed. No Action taken"
            end

            if vm.retired
              raise "ERROR - VM #{vm.name} is already retired - extension bypassed. No Action taken"
            end
          end

          def retirement_extend_days
            @vm_retire_extend_days ||= @handle.object['vm_retire_extend_days'] || DEFAULT_EXTENSION_DAYS
          end

          def extend_retirement
            @handle.log("info", "Number of days to extend: <#{retirement_extend_days}>")
            @handle.log("info", "VM: <#{vm.name}> current retirement date is #{vm.retires_on}")
            @handle.log("info", "Extending retirement <#{retirement_extend_days}> days for VM: <#{vm.name}>")

            vm.extend_retires_on(retirement_extend_days, vm.retires_on)

            @handle.log("info", "VM: <#{vm.name}> new retirement date is #{vm.retires_on}")
            @handle.log("info", "Inspecting retirement vm: <#{vm.retirement_state}>")
          end
        end
      end
    end
  end
end

ManageIQ::Automate::System::Request::VmRetireExtend.new.main
