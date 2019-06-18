#
# Description: This method marks the VM as retired
#

vm = $evm.root['vm']
if vm && !vm.retired?
  vm.finish_retirement
  $evm.create_notification(:type => :vm_retired, :subject => vm)
end
