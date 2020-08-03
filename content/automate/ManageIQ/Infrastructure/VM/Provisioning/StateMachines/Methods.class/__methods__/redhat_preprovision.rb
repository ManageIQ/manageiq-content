#
# Description: This default method is used to apply PreProvision customizations for RHEV provisioning
#

module ManageIQ
  module Automate
    module Infrastructure
      module VM
        module Provisioning
          module StateMachines
            module Methods
              class RedhatPreprovision
                def initialize(handle = $evm)
                  @handle = handle
                  @set_vlan  = false
                  @set_notes = true
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

                def product
                  @product ||= template.operating_system&.product_name&.downcase
                end

                def log(level, msg, update_message = false)
                  @handle.log(level, msg)
                  @handle.root['miq_provision'].message = msg if @handle.root['miq_provision'] && update_message
                end

                def process_customization
                  log(:info, "Template:<#{template.name}> Vendor:<#{template.vendor}> Product:<#{product}>")

                  if @set_vlan
                    # Set default VLAN here if one was not chosen in the dialog?
                    # The format needs to be "#{vnic_profile_name} (#{network_name})"
                    default_vlan = "ovirtmgmt (ovirtmgmt)"

                    if prov.get_option(:vlan).nil?
                      prov.set_vlan(default_vlan)
                      log(:info, "Provisioning object <:vlan> updated with <#{default_vlan}>")
                    end
                  end

                  if @set_notes
                    log(:info, "Processing set_notes...", true)
                    vmdescription = prov.get_option(:vm_description)

                    # Setup VM Annotations
                    vm_notes =  "Owner: #{prov.get_option(:owner_first_name)} #{prov.get_option(:owner_last_name)}"
                    vm_notes += "\nEmail: #{prov.get_option(:owner_email)}"
                    vm_notes += "\nSource Template: #{template.name}"
                    vm_notes += "\nCustom Description: #{vmdescription}" unless vmdescription.nil?
                    prov.set_vm_notes(vm_notes)
                    log(:info, "Provisioning object <:vm_notes> updated with <#{vm_notes}>")
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
end

ManageIQ::Automate::Infrastructure::VM::Provisioning::StateMachines::Methods::RedhatPreprovision.new.main
