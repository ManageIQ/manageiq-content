profile_name = $evm.root.attributes['dialog_name']
server_id = $evm.root.attributes['dialog_server']
service_template_object = $evm.root['service_template_provision_task'].source
template_id = service_template_object.options[:server_profile_template_id]

if template_id.nil? || (template_id == "")
  template_id = $evm.root.attributes['dialog_template']
end

manager = $evm.vmdb(:physical_server)
manager.create_server_profile_and_deploy_task(template_id, server_id, profile_name)

exit MIQ_OK
