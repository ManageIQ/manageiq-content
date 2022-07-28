$evm.log("info", 'eilam999')

dialog_field = $evm.object

# sort_by: value / description / none
dialog_field["sort_by"] = "value"

# sort_order: ascending / descending
dialog_field["sort_order"] = "ascending"

# data_type: string / integer
dialog_field["data_type"] = "string"

# required: true / false
dialog_field["required"] = true

ems_l = $evm.vmdb(:ext_management_system).where(:type=>'ManageIQ::Providers::Autosde::StorageManager').map { |ems| { ems.id => ems.name} }

dialog_field["values"] = Hash[*ems_l.map(&:to_a).flatten]
exit MIQ_OK
