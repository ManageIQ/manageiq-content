#
# Description: add_VM_to_Service
#

begin 
  $evm.log("info", "Called add_VM_to_Service")
  job_id = $evm.object['job_id']
  vm_name = $evm.object['vm_name']
  $evm.log("info", "Called add_VM_to_Service with job_id: #{job_id} and vm_name: #{vm_name}")
  
  # Lookup for Service associated with ansible tower job_id
  job = $evm.vmdb('orchestration_stack').find_by_ems_ref(job_id)
  if job.nil?
    $evm.log("error", "Can't find Ansible Job with ems_ref: #{job_id}")
    exit MIQ_ERROR
  end
  $evm.log("info", "Found Ansible Job with id: #{job.id} and name: #{job.name}")
  
  # Lookup for Service from Ansible Job (Orchestration Stack)
  resource = $evm.vmdb('service_resource').find_by_resource_id(job.id)
  if resource.nil?
    $evm.log("error", "Can't find Service with resource_id: #{job.id}")
    exit MIQ_ERROR
  end
  $evm.log("info", "Found Resource with id: #{resource.id}")
  
  # Lookup for service from Resource
  service = $evm.vmdb('service').find_by_id(resource.service_id)
  if service.nil?
    $evm.log("error", "Can't find Service with id: #{resource.service_id}")
    exit MIQ_ERROR
  end
  $evm.log("info", "Found Service with id: #{resource.service_id} and name: #{service.name}")
  
  # Lookup for VM with vm_name
  vm = $evm.vmdb('vm').find_by_name(vm_name)
  # or try VmOrTemplate.find_by_name(vm_name)
  if vm.nil?
    $evm.log("error", "Can't find VM with name: #{vm_name}")
    exit MIQ_ERROR
  end
  $evm.log("info", "Found VM with id: #{vm.id} and name: #{vm.name}")

  # Associate VM to Service
  $evm.log("info", "Adding VM: #{vm.name} to service: #{service.name}")
  vm.add_to_service(service)

  exit MIQ_OK
rescue => err
  $evm.log("error", "[#{err}]\n#{err.backtrace.join("\n")}")
  exit MIQ_ERROR
end
