dialog_field = $evm.object
dialog_field["sort_by"] = "value"
dialog_field["sort_order"] = "ascending"
dialog_field["data_type"] = "string"
dialog_field["required"] = true

ems_l = $evm.vmdb(:ext_management_system).where(:type=>'ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager').map { |ems| {ems.id => ems.name} }

dialog_field["values"] = Hash[*ems_l.map(&:to_a).flatten]
exit MIQ_OK
