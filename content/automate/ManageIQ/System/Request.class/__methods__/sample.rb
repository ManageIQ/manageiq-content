module ManageIQ
  module Automate
    module System
      module Request
        class Sample
          def initialize(handle = $evm)
            @handle = handle
          end

          # Calls the class method
          def vm_start
            vm_name = ManageIQ::Automate::System::CommonMethods::StateMachineMethods::Utility.normalize_name(@handle.root['vm'].name)
            @handle.log(:info, "Starting vm #{vm_name}")
            @handle.root['vm'].start
          end

          # Creates an instance and calls the instance method
          def vm_start_ex
            obj = ManageIQ::Automate::System::CommonMethods::StateMachineMethods::Utility.new(@handle.root['vm'].name)
            vm_name = obj.normalize
            @handle.log(:info, "Starting vm #{vm_name}")
            @handle.root['vm'].start
          end
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  ManageIQ::Automate::System::Request::Sample.new.vm_start
end
