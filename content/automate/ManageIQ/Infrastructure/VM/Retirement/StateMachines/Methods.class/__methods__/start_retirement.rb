#
# Description: This method sets the retirement_state to retiring
#
module ManageIQ
  module Automate
    module Infrastructure
      module VM
        module Retirement
          module StateMachines
            module Methods
              class StartRetirement
                def initialize(handle = $evm)
                  @handle = handle
                end

                def main
                  log_info
                  start_retirement(vm)
                end

                private

                def vm
                  @handle.root["vm"].tap do |vm|
                    raise 'VM Object not found' if vm.nil?
                  end
                end

                def log_info
                  @handle.log("info", "Listing Root Object Attributes:")
                  @handle.root.attributes.sort.each { |k, v| @handle.log("info", "\t#{k}: #{v}") }
                  @handle.log("info", "===========================================")
                end

                def vm_validation(vm)
                  if vm.retired?
                    raise 'VM is already retired'
                  end

                  if vm.retiring?
                    raise 'VM is already in the process of being retired'
                  end
                end

                def start_retirement(vm)
                  vm_validation(vm)
                  @handle.log('info', "VM before start_retirement: #{vm.inspect} ")
                  @handle.create_notification(:type => :vm_retiring, :subject => vm)

                  vm.start_retirement

                  @handle.log('info', "VM after start_retirement: #{vm.inspect} ")
                end
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Infrastructure::VM::Retirement::StateMachines::Methods::StartRetirement.new.main
