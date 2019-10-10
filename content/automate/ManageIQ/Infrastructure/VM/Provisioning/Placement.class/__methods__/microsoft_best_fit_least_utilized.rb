#
# Description: This method is used to find all hosts, datastores that are the least utilized
#

def clear_host(prov)
  prov.set_option(:placement_host_name, [nil, nil])
end

prov = $evm.root["miq_provision"]
vm   = prov.vm_template
raise "VM not specified" if vm.nil?

ems = vm.ext_management_system
raise "EMS not found for VM [#{vm.name}]" if ems.nil?

# Log space required
$evm.log("info", "vm=[#{vm.name}], space required=[#{vm.provisioned_storage}]")

host = storage = nil
min_registered_vms = nil
prov.eligible_hosts.each do |h|
  next if h.maintenance
  next unless h.power_state == "on"
  nvms = h.vms.length

  # Setting the host to filter eligible storages
  prov.set_host(h)

  if min_registered_vms.nil? || nvms < min_registered_vms
    # Filter out storages that do not have enough free space for the Vm
    storages = prov.eligible_storages.find_all { |s| s.free_space > vm.provisioned_storage }
    s = storages.max_by(&:free_space)
    unless s.nil?
      host    = h
      storage = s
      min_registered_vms = nvms
    end
  end
end

# Set host and storage
host ? prov.set_host(host) : clear_host(prov)
prov.set_storage(storage) if storage

$evm.log("info", "vm=[#{vm.name}] host=[#{host.try(:name)}] storage=[#{storage.try(:name)}]")
