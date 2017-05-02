#
# Description: This method marks the VM as retired
#

vm = $evm.root['vm']
vm.finish_retirement if vm
$evm.create_notification(:type => :vm_retired, :subject => vm) if vm
