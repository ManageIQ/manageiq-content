# Description: get unassigned servers
$evm.log("info", 'selected_ems for servers')

dialog_field = $evm.object
dialog_field["sort_by"] = "value"
dialog_field["sort_order"] = "ascending"
dialog_field["data_type"] = "string"
dialog_field["required"] = true

selected_ems_id = $evm.root.attributes['dialog_ems']
selected_ems = $evm.vmdb(:ext_management_system).find_by(:id =>selected_ems_id)
$evm.log("info", 'selected_ems for servers')
$evm.log("info", selected_ems.name)

servers = selected_ems.physical_servers
profiles = selected_ems.physical_server_profiles
profiles_with_server = profiles.reject { |p| p["assigned_server_id"].nil? }
servers_with_profile = profiles_with_server.pluck("assigned_server_id")

commission_servers_without_profile = servers.select { |s| !s["name"].nil? && !s.id.in?(servers_with_profile) }
servers_finale = commission_servers_without_profile.map { |t| {t.ems_ref => t.name} }

dialog_field["values"] = Hash[*servers_finale.map(&:to_a).flatten]

exit MIQ_OK
