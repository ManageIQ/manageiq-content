#
# Description: This method validates the provisioning request using the values
# [max_vms, max_cpus, max_memory, max_retirement_days] from values in the following order:
# 1. In the model
# 2. Template tags - This looks at the source provisioning template/VM for the following tag
# category values: [prov_max_cpu, prov_max_vm, prov_max_memory, prov_max_retirement_days]
#
module ManageIQ
  module Automate
    module Cloud
      module VM
        module Provisioning
          module StateMachines
            module ProvisionRequestApproval
              class ValidateRequest
                def initialize(handle = $evm)
                  @handle = handle
                end

                def main
                  initialize_variables
                  validate_max_cpus
                  validate_max_vms
                  validate_max_memory
                  validate_max_retirement_days
                  update_msg if @approval_req == true
                end

                private

                def initialize_variables
                  @prov = @handle.root['miq_request']
                  @prov_resource = @prov.resource
                  raise "Provisioning Request not found" if @prov.nil? || @prov_resource.nil?

                  # Get template information
                  @template = @prov_resource.try(:vm_template)
                  raise "VM template not specified" if @template.nil?

                  # Initialize variables used
                  @approval_req = false
                  @reason1 = @reason2 = @reason3 = @reason4 = nil

                  @desired_nvms = @prov_resource.get_option(:number_of_vms).to_i
                end

                ############################################################
                # Validate max_cpus by first checking the below            #
                # value, then check the model and finally the template tag #
                ############################################################
                def validate_max_cpus
                  # Set max_vms here to override the model
                  max_cpus = nil

                  # Use value from model unless specified above
                  max_cpus ||= @handle.object['max_cpus']

                  @handle.log("info", "Auto-Approval Threshold(Model):<max_cpus=#{max_cpus}> detected") if max_cpus

                  max_cpus = nil if max_cpus == '0'

                  # Get Template Tag
                  prov_max_cpus = @template.tags(:prov_max_cpu).first

                  # If template is tagged then override
                  if prov_max_cpus
                    @handle.log("info", "Auto-Approval Threshold(Tag):<prov_max_cpus=#{prov_max_cpus}> from template:<#{@template.name}> detected")
                    max_cpus = prov_max_cpus.first.to_i
                  end

                  # Validate max_cpus if not nil or empty
                  if max_cpus.present?
                    desired_cpus = requested_cpu
                    if desired_cpus > max_cpus.to_i
                      @handle.log('warn', "Auto-Approval Threshold(Warning): Number of vCPUs requested:<#{desired_cpus}> exceeds:<#{max_cpus}>")
                      @approval_req = true
                      @reason1 = "Requested CPUs #{desired_cpus} limit is #{max_cpus}"
                    end
                  end
                end

                ############################################################
                # Validate max_vms by first checking the below             #
                # value, then check the model and finally the template tag #
                ############################################################
                def validate_max_vms
                  # Set max_vms here to override the model
                  max_vms = nil

                  # Use value from model unless specified above
                  max_vms ||= @handle.object['max_vms']
                  unless max_vms.nil?
                    @handle.log("info", "Auto-Approval Threshold(Model):<max_vms=#{max_vms}> detected")
                  end

                  # Reset to nil if value is zero
                  max_vms = nil if max_vms == '0'

                  # Get Template Tag
                  prov_max_vms = @template.tags(:prov_max_vm).first

                  # If template is tagged then override
                  if prov_max_vms
                    @handle.log("info", "Auto-Approval Threshold(Tag):<prov_max_vms=#{prov_max_vms}> from template:<#{@template.name}> detected")
                    max_vms = prov_max_vms.to_i
                  end

                  # Validate max_vms if not nil or empty
                  if max_vms.present?
                    if @desired_nvms && (@desired_nvms.to_i > max_vms.to_i)
                      @handle.log('warn', "Auto-Approval Threshold(Warning): Number of VMs requested:<#{@desired_nvms}> exceeds:<#{max_vms}>")
                      @approval_req = true
                      @reason3 = "Requested VMs #{@desired_nvms} limit is #{max_vms}"
                    end
                  end
                end

                ############################################################
                # Validate max_memory by first checking the below          #
                # value, then check the model and finally the template tag #
                ############################################################
                def validate_max_memory
                  # Set max_memory here to override the model
                  max_memory = nil

                  # Use value from model unless specified above
                  max_memory ||= @handle.object['max_memory']
                  unless max_memory.nil?
                    @handle.log("info", "Auto-Approval Threshold(Model):<max_memory=#{max_memory}> detected")
                  end

                  # Reset to nil if value is zero
                  max_memory = nil if max_memory == '0'

                  # Get Tag
                  prov_max_memory = @template.tags(:prov_max_memory).first

                  # If template is tagged then override
                  if prov_max_memory
                    @handle.log("info", "Auto-Approval Threshold(Tag):<prov_max_memory=#{prov_max_memory}> from template:<#{@template.name}> detected")
                    max_memory = prov_max_memory.to_i
                  end

                  # Validate max_memory if not nil or empty
                  if max_memory.present?
                    desired_mem = requested_memory
                    if desired_mem && (desired_mem.to_i > max_memory.to_i)
                      @handle.log("info", "Auto-Approval Threshold(Warning): Number of vRAM requested: \
                      <#{desired_mem.to_s(:human_size)}> exceeds:<#{max_memory.to_s(:human_size)}>")
                      @approval_req = true
                      @reason2 = "Requested Memory #{desired_mem.to_s(:human_size)} limit is #{max_memory}"
                    end
                  end
                end

                ############################################################
                # Validate max_retirement_days by first checking the below #
                # value, then check the model and finally the template tag #
                ############################################################
                def validate_max_retirement_days
                  # Set max_retirement_days here to override the model
                  max_retirement_days = nil

                  # Use value from model unless specified above
                  max_retirement_days ||= @handle.object['max_retirement_days']
                  unless max_retirement_days.nil?
                    @handle.log("info", "Auto-Approval Threshold(Model):<max_retirement_days=#{max_retirement_days}> detected")
                  end

                  # Reset to nil if value is zero
                  max_retirement_days = nil if max_retirement_days == '0'

                  # Get Tag
                  prov_max_retirement_days = @template.tags(:prov_max_retirement_days).first

                  # If template is tagged then override
                  if prov_max_retirement_days
                    @handle.log("info", "Auto-Approval Threshold(Tag):<prov_max_retirement_days=#{prov_max_retirement_days}> from template:<#{@template.name}> detected")
                    max_retirement_days = prov_max_retirement_days.to_i
                  end

                  # Validate max_retirement_days if not nil or empty
                  if max_retirement_days.present?
                    desired_retirement_days = @prov_resource.get_retirement_days

                    if desired_retirement_days && (desired_retirement_days.to_i > max_retirement_days.to_i)
                      @handle.log('warn', "Auto-Approval Threshold(Warning): Number of Retirement Days requested:<#{desired_retirement_days}> exceeds:<#{max_retirement_days}>")
                      @approval_req = true
                      @reason4 = "Requested Retirement Days #{desired_retirement_days} limit is #{max_retirement_days}"
                    end
                  end
                end

                # Update Message to Requester
                def update_msg
                  msg =  "Request was not auto-approved for the following reasons: "
                  msg += "(#{@reason1}) " if @reason1
                  msg += "(#{@reason2}) " if @reason2
                  msg += "(#{@reason3}) " if @reason3
                  msg += "(#{@reason4}) " if @reason4
                  @prov_resource.set_message(msg)
                  @handle.log("info", "Auto-Approval #{msg}")

                  @handle.root['ae_result'] = 'error'
                  @handle.object['reason'] = msg
                end

                def requested_memory
                  flavor_value(:memory).to_i * @desired_nvms
                end

                def requested_cpu
                  flavor_value(:cpus).to_i * @desired_nvms
                end

                def flavor_value(option)
                  id = @prov_resource.get_option(:instance_type)
                  flavor = @handle.vmdb('flavor', id) if id
                  flavor[option] if flavor
                end
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Cloud::VM::Provisioning::StateMachines::ProvisionRequestApproval::ValidateRequest.new.main
