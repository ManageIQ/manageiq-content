service = $evm.root['service']
if service.nil?
  $evm.log('error', 'get_retirement_entrypoint: missing service object')
  exit MIQ_ABORT
end

entry_point = service.automate_retirement_entrypoint
$evm.log("info", "Starting get_retirement_entrypoint: #{entry_point}")
if entry_point.blank?
  entry_point = if service.type == "ServiceAnsiblePlaybook"
                  '/Service/Generic/StateMachines/GenericLifecycle/retire'
                else
                  '/Service/Retirement/StateMachines/ServiceRetirement/Default'
                end
  $evm.log("info", "get_retirement_entrypoint not specified using default: #{entry_point}")
end

$evm.root['retirement_entry_point'] = entry_point
$evm.root['service_action'] = 'Retirement'
$evm.log("info", "Ending get_retirement_entrypoint: #{entry_point}")
