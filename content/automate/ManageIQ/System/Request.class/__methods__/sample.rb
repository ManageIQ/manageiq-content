module ManageIQ
  module Automate
    module System
      module Request
        class Sample
          def initialize(handle = $evm)
            @handle = handle
          end
         
          def vm_start
            vm_name = ManageIQ::Automate::System::CommonMethods::StateMachineMethods::Utility.normalize_name(@handle.root['vm'].name)
            @handle.log(:info, "Starting vm #{vm_name}")
            @handle.root['vm'].start
          end
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  ManageIQ::Automate::System::Request::Sample.new.vm_start
end
