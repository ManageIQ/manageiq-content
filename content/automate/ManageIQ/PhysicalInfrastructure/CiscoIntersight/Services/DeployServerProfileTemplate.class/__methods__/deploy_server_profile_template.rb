template_id = $evm.root.attributes['dialog_template']
profile_name = $evm.root.attributes['dialog_name']
server_id = $evm.root.attributes['dialog_server']

manager = $evm.vmdb(:physical_server)
manager.create_server_profile_and_deploy_task(template_id.to_s, server_id, profile_name)

exit MIQ_OK
