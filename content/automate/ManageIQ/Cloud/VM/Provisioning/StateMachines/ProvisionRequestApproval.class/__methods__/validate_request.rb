#
# Description: This method validates the provisioning request using the values
# [max_vms, max_cpus, max_memory, max_retirement_days] from values in the following order:
# 1. In the model
# 2. Template tags - This looks at the source provisioning template/VM for the following tag
# category values: [prov_max_cpu, prov_max_vm, prov_max_memory, prov_max_retirement_days]
#

def vmdb_object(model, id)
  $evm.vmdb(model, id.to_i) if model && id
end

def requested_memory(prov_resource, number_of_vms)
  flavor_value(prov_resource, :memory).to_i * number_of_vms
end

def requested_cpu(prov_resource, number_of_vms)
  flavor_value(prov_resource, :cpus).to_i * number_of_vms
end

def flavor_value(prov_resource, option)
  flavor = vmdb_object('flavor', prov_resource.get_option(:instance_type))
  flavor[option] if flavor
end

# Initialize Variables
prov = $evm.root['miq_request']
prov_resource = prov.resource
raise "Provisioning Request not found" if prov.nil? || prov_resource.nil?

# Get template information
template = prov.resource.vm_template rescue nil
raise "VM template not specified" if template.nil?

# Initialize variables used
approval_req = false
reason1      = nil
reason2      = nil
reason3      = nil
reason4      = nil

desired_nvms = prov_resource.get_option(:number_of_vms).to_i
###################################
#
# max_cpus:
# Validate max_cpus by first checking the below
# value, then check the model and finally the template tag
#
###################################
# Set max_cpus here to override the model
max_cpus = nil

# Use value from model unless specified above
max_cpus ||= $evm.object['max_cpus']
unless max_cpus.nil?
  $evm.log("info", "Auto-Approval Threshold(Model):<max_cpus=#{max_cpus}> detected")
end

# Reset to nil if value is zero
max_cpus = nil if max_cpus == '0'

# Get Template Tag
prov_max_cpus = template.tags(:prov_max_cpu).first
# If template is tagged then override
unless prov_max_cpus.nil?
  $evm.log("info", "Auto-Approval Threshold(Tag):<prov_max_cpus=#{prov_max_cpus}> from template:<#{template.name}> detected")
  max_cpus = prov_max_cpus.first.to_i
end

# Validate max_cpus if not nil or empty
unless max_cpus.blank?
  desired_cpus = requested_cpu(prov_resource, desired_nvms)
  if desired_cpus > max_cpus.to_i
    $evm.log('warn', "Auto-Approval Threshold(Warning): Number of vCPUs requested:<#{desired_cpus}> exceeds:<#{max_cpus}>")
    approval_req = true
    reason1 = "Requested CPUs #{desired_cpus} limit is #{max_cpus}"
  end
end

###################################
#
# max_vms:
# Validate max_vms by first checking the below
# value, then check the model and finally the template tag
#
###################################
# Set max_vms here to override the model
max_vms = nil

# Use value from model unless specified above
max_vms ||= $evm.object['max_vms']
unless max_vms.nil?
  $evm.log("info", "Auto-Approval Threshold(Model):<max_vms=#{max_vms}> detected")
end

# Reset to nil if value is zero
max_vms = nil if max_vms == '0'

# Get Template Tag
prov_max_vms = template.tags(:prov_max_vm).first
# If template is tagged then override
unless prov_max_vms.nil?
  $evm.log("info", "Auto-Approval Threshold(Tag):<prov_max_vms=#{prov_max_vms}> from template:<#{template.name}> detected")
  max_vms = prov_max_vms.to_i
end

# Validate max_vms if not nil or empty
unless max_vms.blank?
  if desired_nvms && (desired_nvms.to_i > max_vms.to_i)
    $evm.log('warn', "Auto-Approval Threshold(Warning): Number of VMs requested:<#{desired_nvms}> exceeds:<#{max_vms}>")
    approval_req = true
    reason3 = "Requested VMs #{desired_nvms} limit is #{max_vms}"
  end
end

###################################
#
# max_memory:
# Validate max_memory by first checking the below
# value, then check the model and finally the template tag
#
###################################
# Set max_memory here to override the model
max_memory = nil

# Use value from model unless specified above
max_memory ||= $evm.object['max_memory']
unless max_memory.nil?
  max_memory = max_memory.to_i.megabytes
  $evm.log("info", "Auto-Approval Threshold(Model):<max_memory=#{max_memory.to_s(:human_size)}> detected")
end

# Reset to nil if value is zero
max_memory = nil if max_memory == '0'

# Get Tag
prov_max_memory = template.tags(:prov_max_memory).first
# If template is tagged then override
unless prov_max_memory.nil?
  prov_max_memory = prov_max_memory.to_i.megabytes
  $evm.log("info", "Auto-Approval Threshold(Tag):<prov_max_memory=#{prov_max_memory.to_s(:human_size)}> from template:<#{template.name}> detected")
  max_memory = prov_max_memory.to_i
end

# Validate max_memory if not nil or empty
unless max_memory.blank?
  desired_mem = requested_memory(prov_resource, desired_nvms)
  if desired_mem && (desired_mem.to_i > max_memory.to_i)
    $evm.log("info", "Auto-Approval Threshold(Warning): Number of vRAM requested: \
    <#{desired_mem.to_s(:human_size)}> exceeds:<#{max_memory.to_s(:human_size)}>")
    approval_req = true
    reason2 = "Requested Memory #{desired_mem.to_s(:human_size)} limit is #{max_memory.to_s(:human_size)}"
  end
end

###################################
#
# max_retirement_days:
# Validate max_retirement_days by first checking the below
# value, then check the model and finally the template tag
#
###################################
# Set max_retirement_days here to override the model
max_retirement_days = nil

# Use value from model unless specified above
max_retirement_days ||= $evm.object['max_retirement_days']
unless max_retirement_days.nil?
  $evm.log("info", "Auto-Approval Threshold(Model):<max_retirement_days=#{max_retirement_days}> detected")
end

# Reset to nil if value is zero
max_retirement_days = nil if max_retirement_days == '0'

# Get Tag
prov_max_retirement_days = template.tags(:prov_max_retirement_days).first
# If template is tagged then override
unless prov_max_retirement_days.nil?
  $evm.log("info", "Auto-Approval Threshold(Tag):<prov_max_retirement_days=#{prov_max_retirement_days}> from template:<#{template.name}> detected")
  max_retirement_days = prov_max_retirement_days.to_i
end

# Validate max_retirement_days if not nil or empty
unless max_retirement_days.blank?
  desired_retirement_days = prov_resource.get_retirement_days
  if desired_retirement_days && (desired_retirement_days.to_i > max_retirement_days.to_i)
    $evm.log('warn', "Auto-Approval Threshold(Warning): Number of Retirement Days requested:<#{desired_retirement_days}> exceeds:<#{max_retirement_days}>")
    approval_req = true
    reason4 = "Requested Retirement Days #{desired_retirement_days} limit is #{max_retirement_days}"
  end
end

######################################
#
# Update Message to Requester
#
######################################
if approval_req == true
  msg =  "Request was not auto-approved for the following reasons: "
  msg += "(#{reason1}) " unless reason1.nil?
  msg += "(#{reason2}) " unless reason2.nil?
  msg += "(#{reason3}) " unless reason3.nil?
  msg += "(#{reason4}) " unless reason4.nil?
  prov_resource.set_message(msg)
  $evm.log("info", "Auto-Approval #{msg}")

  $evm.root['ae_result'] = 'error'
  $evm.object['reason'] = msg
end
