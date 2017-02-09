#
# Description: This method updates the provisioning status and retries
# from the Placement step.
# Required inputs: status
#

prov = $evm.root['miq_provision']
unless prov
  $evm.log(:error, "miq_provision object not provided")
  exit(MIQ_STOP)
end
status = $evm.inputs['status']
$evm.root['ae_result'] = 'restart' 
$evm.root['ae_next_state'] = 'Placement'
$evm.log("info", "Provisioning #{prov.get_option(:vm_target_name)} failed, retrying placement.")

# Update Status Message
updated_message  = "[#{$evm.root['miq_server'].name}] "
updated_message += "VM [#{prov.get_option(:vm_target_name)}] "
updated_message += "Step [#{$evm.root['ae_state']}] "
updated_message += "Status [#{status}] "
updated_message += "Message [#{prov.message}] "
prov.miq_request.user_message = updated_message
prov.message = status

if $evm.root['ae_result'] == "error"
  $evm.create_notification(:level => "error", :subject => prov.miq_request, \
                           :message => "VM Provision Error: #{updated_message}")
end
