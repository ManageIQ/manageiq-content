# Create a volume after service request

$evm.log("info", 'creating a volume after order request.')
ems_id = $evm.root.attributes['dialog_ems']

size = $evm.root.attributes['dialog_size']

if size == 'custom'
  size = $evm.root.attributes['dialog_custom']
end
options = {
  "name"               => $evm.root.attributes['dialog_name'],
  "size"               => size,
  "count"              => 1,
  "storage_service_id" => $evm.root.attributes['dialog_pool']
}

cv = $evm.vmdb(:cloud_volume)
user = $evm.root['user']
cv.create_volume_task(ems_id, user.userid, options)
