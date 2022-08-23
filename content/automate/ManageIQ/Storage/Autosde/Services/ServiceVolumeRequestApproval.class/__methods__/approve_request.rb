# Create a volume after service request

$evm.log("info", 'creating a volume after order request.')
ems = $evm.vmdb(:ext_management_system).where(:id=>$evm.root.attributes['dialog_ems']).first

size = $evm.root.attributes['dialog_size']

if size == 'custom'
  size = $evm.root.attributes['dialog_custom']
end
options = {
            "name" => $evm.root.attributes['dialog_name'],
            "size" => size,
            "count" => 1,
            "storage_service_id" => $evm.root.attributes['dialog_pool']
}

cv = $evm.vmdb(:cloud_volume)

cv.create_volume_task(ems.id, options)
