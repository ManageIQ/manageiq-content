#
# Description: This method is executed when the reconfigure request is NOT auto-approved
#

# Get objects
msg = $evm.object['reason']
$evm.log('info', msg.to_s)

# Raise automation event: request_pending
$evm.root["miq_request"].pending
