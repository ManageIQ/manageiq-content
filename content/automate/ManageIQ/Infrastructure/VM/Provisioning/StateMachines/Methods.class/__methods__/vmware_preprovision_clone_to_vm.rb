#
# Description: This default method is used to apply PreProvision customizations during the cloning to a VM:
# 1. Customization Spec
# 2. VLAN
# 3. VM Description/Annotations
# 4. Resource Pool
# 5. Tag Inheritance

module ManageIQ
  module Automate
    module Infrastructure
      module VM
        module Provisioning
          module StateMachines
            module Methods
              class VmwarePreprovisionCloneToVm
                def initialize(handle = $evm)
                  @handle = handle
                  @vlan       = false
                  @notes      = true
                  @tags       = true
                  @customspec = false
                end

                def main
                  @handle.log("info", "Provision Type: <#{prov_type}>")
                  @handle.log("info", "Source Product: <#{product}>")

                  set_customization_spec if @customspec
                  set_vlan               if @vlan
                  set_notes              if @notes
                  set_tags               if @tags
                end

                private

                def prov
                  @prov ||= @handle.root["miq_provision"].tap do |req|
                    raise 'miq_provision not specified' if req.nil?
                  end
                end

                def prov_type
                  @prov_type ||= prov.provision_type
                end

                def template
                  @template ||= prov.vm_template.tap do |req|
                    raise 'vm_template not specified' if req.nil?
                  end
                end

                def product
                  @product ||= template.operating_system&.product_name&.downcase
                end

                def set_customization_spec
                  ###################################
                  # Set the customization spec here
                  # If one selected in dialog it will be used,
                  # else it will map the customization spec based on the
                  # the entry below
                  ###################################
                  customization_spec = "my-custom-spec"

                  # Skip automatic customization spec mapping if template is 'Other'
                  if product.include?("other")
                    @handle.log("info", "Skipping automatic customization spec mapping")
                  elsif prov.get_option(:sysprep_custom_spec).nil?
                    prov.set_customization_spec(customization_spec)
                    @handle.log("info", "Provisioning object updated - <:sysprep_custom_spec> = <#{customization_spec}>")
                  end
                end

                def set_vlan
                  ###################################
                  # Was a VLAN selected in dialog?
                  # If not you can set one here.
                  ###################################
                  default_vlan = "vlan1"

                  if prov.get_option(:vlan).nil?
                    prov.set_vlan(default_vlan)
                  end
                end

                def set_notes
                  ###################################
                  # Set the VM Description and VM Annotations  as follows:
                  # The example would allow user input in provisioning dialog "vm_description"
                  # to be added to the VM notes
                  ###################################
                  vmdescription = prov.get_option(:vm_description)

                  # Setup VM Annotations
                  vm_notes =  "Owner: #{prov.get_option(:owner_first_name)} #{prov.get_option(:owner_last_name)}"
                  vm_notes += "\nEmail: #{prov.get_option(:owner_email)}"
                  vm_notes += "\nSource VM: #{prov.vm_template.name}"
                  vm_notes += "\nCustom Description: #{vmdescription}" unless vmdescription.nil?
                  prov.set_vm_notes(vm_notes)
                  @handle.log("info", "Provisioning object <:vm_notes> updated with <#{vm_notes}>")
                end

                def set_tags
                  ###################################
                  #
                  # Inherit parent VM's tags and apply
                  # them to the cloned VM
                  #
                  ###################################

                  # List of tag categories to carry over
                  tag_categories_to_migrate = %w[environment department location function]

                  # Assign variables
                  prov_tags = prov.get_tags
                  @handle.log("info", "Provisioning Tags: <#{prov_tags.inspect}>")
                  template_tags = template.tags
                  @handle.log("info", "Template Tags: <#{template_tags.inspect}>")

                  # Loop through each source tag for matching categories
                  template_tags.each do |cat_tagname|
                    category, tag_value = cat_tagname.split('/')
                    @handle.log("info", "Processing Tag Category: <#{category}> Value: <#{tag_value}>")
                    next unless tag_categories_to_migrate.include?(category)

                    prov.add_tag(category, tag_value)
                    @handle.log("info", "Updating Provisioning Tags with Category: <#{category}> Value: <#{tag_value}>")
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

ManageIQ::Automate::Infrastructure::VM::Provisioning::StateMachines::Methods::VmwarePreprovisionCloneToVm.new.main
