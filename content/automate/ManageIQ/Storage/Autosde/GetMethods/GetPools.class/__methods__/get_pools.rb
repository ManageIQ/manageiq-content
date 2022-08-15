#
# Description: get pools from autosde
dialog_field = $evm.object

# sort_by: value / description / none
dialog_field["sort_by"] = "value"

# sort_order: ascending / descending
dialog_field["sort_order"] = "ascending"

# data_type: string / integer
dialog_field["data_type"] = "string"

# required: true / false
dialog_field["required"] = true

selected_ems = $evm.root.attributes['dialog_ems']
storage_services = $evm.vmdb(:storage_service).where(:ems_id=>selected_ems)
ss_l = storage_services.map { |service| {service.ems_ref => service.name }}

dialog_field["values"] = Hash[*ss_l.map(&:to_a).flatten]

exit MIQ_OK
