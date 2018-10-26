request = $evm.root['miq_request']
message = $evm.object['reason']
$evm.log('info', "Request denied because of #{message}")
request.message = message
request.deny('admin', msg = message)
