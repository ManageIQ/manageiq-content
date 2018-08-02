module ManageIQ
  module Automate
    module Cloud
      module VM
        module Retirement
          module StateMachines
            module VMRetirement
              class UpdateRetirementStatus
                def initialize(handle = $evm)
                  @handle = handle
                end

                def main
                  vm = @handle.root['vm']

                  updated_message = update_status_message(vm, @handle.inputs['status'])

                  if @handle.root['ae_result'] == "error"
                    @handle.create_notification(:level   => "error",
                                                :subject => "vm",
                                                :message => "VM Retirement Error: #{updated_message}")
                    @handle.log(:error, "VM Retirement Error: #{updated_message}")
                  end
                end

                private

                def update_status_message(vm, status)
                  updated_message  = "Server [#{@handle.root['miq_server'].name}] "
                  updated_message += "Step [#{@handle.root['ae_state']}] "
                  updated_message += "Status [#{status}] "
                  updated_message += "Current Retry Number [#{@handle.root['ae_state_retries']}]" if @handle.root['ae_result'] == 'retry'

                  if @handle.root['ae_result'] == 'error'
                    if @handle.root['ae_state'].downcase == 'startretirement'
                      msg = 'Cannot continue because VM is '
                      msg += vm ? "#{vm.retirement_state}." : 'nil.'
                      @handle.log('info', msg)
                      updated_message += msg
                    elsif vm
                      vm.retirement_state = 'error'
                    end
                  end

                  if @handle.root['vm_retire_task']
                    task = @handle.root['vm_retire_task']
                    task.miq_request.user_message = updated_message
                    task.message = status

                    updated_message
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Cloud::VM::Retirement::StateMachines::VMRetirement::UpdateRetirementStatus.new.main
