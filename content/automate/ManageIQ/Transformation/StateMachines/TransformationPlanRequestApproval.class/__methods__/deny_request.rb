request = $evm.root['miq_request']
message = $evm.object['reason']
$evm.log('info', "Request denied because of #{message}")
request.set_message(message)
request.deny('admin', message)
