#
# Description: This default method is used to apply PreProvision customizations for VMware
#

module ManageIQ
  module Automate
    module Infrastructure
      module VM
        module Provisioning
          module StateMachines
            module Methods
              class VmwarePreprovision
                def initialize(handle = $evm)
                  @handle            = handle
                  @set_vlan          = false
                  @set_folder        = true
                  @set_resource_pool = false
                  @set_notes         = true
                end

                def main
                  log(:info, "Provision:<#{prov.id}> Request:<#{prov.miq_provision_request.id}> Type:<#{prov.type}>")
                  process_customization
                end

                private

                def prov
                  @prov ||= @handle.root["miq_provision"].tap do |req|
                    raise 'miq_provision not specified' if req.nil?
                  end
                end

                def template
                  @template ||= prov.vm_template.tap do |req|
                    raise 'vm_template not specified' if req.nil?
                  end
                end

                def provider
                  @provider ||= template.ext_management_system.tap do |ems|
                    raise 'ext_management_system not specified' if ems.nil?
                  end
                end

                def product
                  @product ||= template.operating_system&.product_name&.downcase
                end

                def bitness
                  @bitness ||= template.operating_system['bitness']
                end

                def log(level, msg, update_message = false)
                  @handle.log(level, msg)
                  @handle.root['miq_provision'].message = msg if @handle.root['miq_provision'] && update_message
                end

                def set_vlan
                  log(:info, "Processing set_vlan...", true)
                  ###################################
                  # Was a VLAN selected in dialog?
                  # If not you can set one here.
                  ###################################
                  if prov.get_option(:vlan).nil?
                    default_vlan = "VM Network"
                    # default_dvs = "portgroup1"

                    prov.set_vlan(default_vlan)
                    # prov.set_dvs(default_dvs)
                    log(:info, "Provisioning object <:vlan> updated with <#{prov.get_option(:vlan)}>")
                  end
                  log(:info, "Processing set_vlan...Complete", true)
                end

                def set_folder
                  log(:info, "Processing set_folder...", true)
                  ###################################
                  # Drop the VM in the targeted folder if no folder was chosen in the dialog.
                  # The vCenter folder must exist for the VM to be placed correctly,
                  # Otherwise the VM will be placed at the Data Center level.
                  ###################################
                  if prov.get_option(:placement_folder_name).nil?
                    datacenter = template.v_owning_datacenter

                    # prov.get_folder_paths.each { |key, path| log(:info, "Eligible folders:<#{key.inspect}> - <#{path.inspect}>") }
                    prov.set_folder(datacenter)
                    log(:info, "Provisioning object <:placement_folder_name> updated with <#{prov.options[:placement_folder_name].inspect}>")
                  else
                    log(:info, "Placing VM in folder: <#{prov.options[:placement_folder_name].inspect}>")
                  end
                  log(:info, "Processing set_folder...Complete", true)
                end

                def set_resource_pool
                  log(:info, "Processing set_resource_pool...", true)
                  if prov.get_option(:placement_rp_name).nil?
                    ############################################
                    # Find and set the Resource Pool for a VM:
                    ############################################
                    default_resource_pool = 'MyResPool'
                    respool = prov.eligible_resource_pools.detect { |c| c.name.casecmp(default_resource_pool) == 0 }
                    log(:info, "Provisioning object <:placement_rp_name> updated with <#{respool.name.inspect}>")
                    prov.set_resource_pool(respool)
                  end
                  log(:info, "Processing set_resource_pool...Complete", true)
                end

                def set_notes
                  log(:info, "Processing set_notes...", true)
                  vmdescription = prov.get_option(:vm_description)

                  # Setup VM Annotations
                  vm_notes =  "Owner: #{prov.get_option(:owner_first_name)} #{prov.get_option(:owner_last_name)}"
                  vm_notes += "\nEmail: #{prov.get_option(:owner_email)}"
                  vm_notes += "\nSource: #{template.name}"
                  vm_notes += "\nDescription: #{vmdescription}" unless vmdescription.nil?
                  prov.set_vm_notes(vm_notes)
                  log(:info, "Provisioning object <:vm_notes> updated with <#{vm_notes}>")
                end

                def process_customization
                  log(:info, "Template:<#{template.name}> Provider:<#{provider.name}> Vendor:<#{template.vendor}> Product:<#{product}> Bitness:<#{bitness}>")

                  tags = prov.get_tags
                  log(:info, "Provision Tags:<#{tags.inspect}>")
                  set_vlan if @set_vlan
                  set_folder if @set_folder
                  set_resource_pool if @set_resource_pool
                  set_notes if @set_notes

                  log(:info, "Processing set_notes...Complete", true)
                end
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Infrastructure::VM::Provisioning::StateMachines::Methods::VmwarePreprovision.new.main
