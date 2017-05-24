#
# Description: This method updates the vm import status.
# Required inputs: status
#

prov = $evm.root['automation_task']
unless prov
  $evm.log(:error, "automation_task object not provided")
  exit(MIQ_STOP)
end
status = $evm.inputs['status']

vm = $evm.root['vm']
unless vm
  $evm.log(:error, 'vm object not provided')
  exit(MIQ_STOP)
end

# Update Status Message
updated_message  = "[#{$evm.root['miq_server'].name}] "
updated_message += "VM [#{vm.name}] "
updated_message += "Step [#{$evm.root['ae_state']}] "
updated_message += "Status [#{status}] "
updated_message += "Message [#{prov.message}] "
updated_message += "Current Retry Number [#{$evm.root['ae_state_retries']}]" if $evm.root['ae_result'] == 'retry'
prov.miq_request.user_message = updated_message
prov.message = status

if $evm.root['ae_result'] == "error"
  $evm.create_notification(:level => "error", :message => "VM Import Error: #{updated_message}")
  $evm.log(:error, "VM Import Error: #{updated_message}")
end
