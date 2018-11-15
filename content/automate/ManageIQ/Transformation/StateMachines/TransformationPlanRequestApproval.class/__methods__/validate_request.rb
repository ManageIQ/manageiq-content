request = $evm.root['miq_request']

unless request.validate_conversion_hosts
  $evm.object['reason'] = 'No conversion host configured'
  exit MIQ_ABORT
end

request.source_vms.each { |vm| request.approve_vm(vm) if request.validate_vm(vm) }
