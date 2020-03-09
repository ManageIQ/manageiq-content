#
# Description: This default method is used to apply PreProvision customizations as follows:
# 1. VM Description/Annotations
# 2. Target VC Folder
# 3. Tag Inheritance


module ManageIQ
  module Automate
    module Infrastructure
      module VM
        module Provisioning
          module StateMachines
            module Methods
              class VmwarePreprovisionCloneToTemplate
                def initialize(handle = $evm)
                  @handle = handle
                  @folder     = true
                  @notes      = true
                  @tags       = true
                end

                def main
                  @handle.log("info", "Provision Type: <#{prov_type}>")
                  @handle.log("info", "Source Product: <#{product}>")

                  set_notes  if @notes
                  set_folder if @folder
                  set_tags   if @tags
                end

                private

                def set_notes
                  vmdescription = prov.get_option(:vm_description)

                  # Setup VM Annotations
                  vm_notes =  "Owner: #{prov.get_option(:owner_first_name)} #{prov.get_option(:owner_last_name)}"
                  vm_notes += "\nEmail: #{prov.get_option(:owner_email)}"
                  vm_notes += "\nSource Template: #{prov.vm_template.name}"
                  vm_notes += "\nCustom Description: #{vmdescription}" unless vmdescription.nil?
                  prov.set_vm_notes(vm_notes)
                  @handle.log("info", "Provisioning object <:vm_notes> updated with <#{vm_notes}>")
                end

                def set_folder
                  ###################################
                  # Drop the VM in the targeted folder if no folder was chosen in the dialog
                  # The VC folder must exist for the VM to be placed correctly,
                  # Otherwise the VM will be placed at the Data Center level.
                  ###################################
                  datacenter = template.v_owning_datacenter

                  if prov.get_option(:placement_folder_name).nil?
                    prov.set_folder(datacenter)
                    @handle.log("info", "Provisioning object <:placement_folder_name> updated with <#{prov.options[:placement_folder_name].inspect}>")
                  else
                    @handle.log("info", "Placing VM in folder: <#{prov.get_option(:placement_folder_name)}>")
                  end
                end

                def set_tags
                  ###################################
                  #
                  # Inherit parent VM's tags and apply
                  # them to the published template
                  #
                  ###################################

                  # List of tag categories to carry over
                  tag_categories_to_migrate = %w[environment department location function]

                  # Assign variables
                  prov_tags = prov.get_tags
                  @handle.log("info", "Inspecting Provisioning Tags: <#{prov_tags.inspect}>")
                  template_tags = template.tags
                  @handle.log("info", "Inspecting Template Tags: <#{template_tags.inspect}>")

                  # Loop through each source tag for matching categories
                  template_tags.each do |cat_tagname|
                    category, tag_value = cat_tagname.split('/')
                    @handle.log("info", "Processing Tag Category: <#{category}> Value: <#{tag_value}>")
                    next unless tag_categories_to_migrate.include?(category)

                    prov.add_tag(category, tag_value)
                    @handle.log("info", "Updating Provisioning Tags with Category: <#{category}> Value: <#{tag_value}>")
                  end
                end

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
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Infrastructure::VM::Provisioning::StateMachines::Methods::VmwarePreprovisionCloneToTemplate.new.main
