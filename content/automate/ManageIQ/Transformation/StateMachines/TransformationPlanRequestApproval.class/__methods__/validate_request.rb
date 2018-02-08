#
# Description: Placeholder for service request validation
#
prov = $evm.root['miq_request']
prov.source_vms.each { |vm| prov.approve_vm(vm) if prov.validate_vm(vm) }
