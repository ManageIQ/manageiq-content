
ems = $evm.vmdb(:ext_management_system).where(:id=>$evm.root.attributes['dialog_ems']).first
$evm.log("info", 'creating a volume after order request.')

autosde_client=ems.object_send('autosde_client')

if $evm.root.attributes['dialog_size'] != 'custom'
  size = $evm.root.attributes['dialog_size']
else
  size = $evm.root.attributes['dialog_custom']
end

vol_to_create = autosde_client.VolumeCreate(
  :service => $evm.root.attributes['dialog_pool'],
  :name    => $evm.root.attributes['dialog_name'],
  :size    => size,
  :count   => 1
)

new_volume = autosde_client.VolumeApi.volumes_post(vol_to_create)
ems.refresh
exit MIQ_OK