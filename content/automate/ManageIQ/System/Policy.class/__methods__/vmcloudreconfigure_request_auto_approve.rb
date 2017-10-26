#
# Description: This method auto-approves the VM Cloud Reconfiguration request
#
$evm.log("info", "AUTO-APPROVING")
$evm.root["miq_request"].approve("admin", "VM Cloud Reconfiguration Auto-Approved")
