#
# Description: This method is used to Customize the Provisioning Request
# Customization mapping for VMware and VMWare PXE provisioning
#

module ManageIQ
  module Automate
    module Infrastructure
      module VM
        module Provisioning
          module StateMachines
            module Methods
              class VMwareCustomizeRequest
                def initialize(handle = $evm)
                  @handle = handle
                  @mapping = 0
                end

                def main
                  log(:info, "Provision:<#{prov.id}> Request:<#{prov.miq_provision_request.id}> Type:<#{prov.type}>")
                  log(:info, "Template: #{template.name} Provider: #{provider.name} Vendor: #{template.vendor} Product: #{product}")

                  # Build case statement to determine which type of processing is required
                  case prov.type
                  when 'ManageIQ::Providers::Vmware::InfraManager::Provision'
                    ##########################################################
                    # VMware Customization Specification Mapping
                    #
                    # Possible values:
                    #   0 - (Default No Mapping) This option is automatically chosen if it finds a customization
                    #   specification mapping chosen from the dialog
                    #
                    #   1 - CFME will look for a customization specification with
                    #   the exact name as the template name
                    #
                    #   2 - Use this option to use a combination of product name and bitness to
                    #   select your customization specification
                    ##########################################################
                    # @mapping = 0
                    process_vmware

                  when 'ManageIQ::Providers::Vmware::InfraManager::ProvisionViaPxe'
                    ##########################################################
                    # VMware PXE Customization Specification Mapping
                    #
                    # Possible values:
                    #   0 - (DEFAULT No Mapping) This option skips the mapping of pxe images and customization templates
                    #
                    #   1 - CFME will look for a pxe image and a customization template with
                    #   the exact name as  the template name if none were chosen from the provisioning dialog
                    ##########################################################
                    # @mapping = 0
                    process_vmware_pxe

                  else
                    log(:info, "Provisioning Type: #{prov.type} does not match, skipping processing")
                  end
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

                def log(level, msg, update_message = false)
                  @handle.log(level, msg)
                  @handle.root['miq_provision'].message = "#{@method} - #{msg}" if @handle.root['miq_provision'] && update_message
                end

                def set_customspec(prov, spec)
                  prov.set_customization_spec(spec, true) rescue nil
                  log(:info, "Provisioning object updated {:sysprep_custom_spec => #{prov.get_option(:sysprep_custom_spec).inspect}}")
                  log(:info, "Provisioning object updated {:sysprep_spec_override => #{prov.get_option(:sysprep_spec_override)}}")
                end

                def process_vmware
                  # if prov.get_option(:sysprep_custom_spec) || product.include?("other") || prov.provision_type.include?("clone_to_template")
                  if product.include?("other") || prov.provision_type.include?("clone_to_template")
                    @mapping = 0
                  end

                  if @mapping == 1
                    # Automatic customization specification mapping if template is RHEL,Suse or Windows
                    if product.include?("red hat") || product.include?("suse") || product.include?("windows")
                      spec = prov.vm_template.name # to match the template name
                      set_customspec(prov, spec)

                      # Set linux hostname stuff here
                      prov.set_option(:linux_host_name, prov.get_option(:vm_target_name))
                      log(:info, "Provisioning object updated {:linux_host_name => #{prov.get_option(:linux_host_name)}}")
                      prov.set_option(:vm_target_hostname, prov.get_option(:vm_target_name))
                      log(:info, "Provisioning object updated {:hostname => #{prov.get_option(:vm_target_hostname)}}")
                    end
                  elsif @mapping == 2
                    # Use this option to use a combination of product name and bitness to select your customization specification
                    spec = nil # unknown type

                    if product.include?("2003")
                      spec = "W2K3R2-Entx64"  # Windows Server 2003
                    elsif product.include?("2008")
                      spec = "vmware_windows" # Windows Server 2008
                    elsif product.include?("windows 7")
                      spec = "vmware_windows" # Windows7
                    elsif product.include?("suse")
                      spec = "vmware_suse" # Suse
                    elsif product.include?("red hat")
                      spec = "vmware_rhel" # RHEL
                    end
                    log(:info, "VMware Customization Specification: #{spec}")

                    # Set values in provisioning object
                    set_customspec(prov, spec) unless spec.nil?
                  end
                end

                def process_vmware_pxe
                  if product.include?("windows") && @mapping == 1
                    # find the windows image that matches the template name if a PXE Image was NOT chosen in the dialog
                    if prov.get_option(:pxe_image_id).nil?

                      log(:info, "Inspecting Eligible Windows Images: #{prov.eligible_windows_images.inspect}")
                      pxe_image = prov.eligible_windows_images.detect { |pi| pi.name.casecmp(template.name) == 0 }
                      if pxe_image.nil?
                        log(:error, "Failed to find matching PXE Image", true)
                        raise "Failed to find matching PXE Image"
                      else
                        log(:info, "Found matching Windows PXE Image ID: #{pxe_image.id} Name: #{pxe_image.name} Description: #{pxe_image.description}")
                      end
                      prov.set_windows_image(pxe_image)
                      log(:info, "Provisioning object updated {:pxe_image_id => #{prov.get_option(:pxe_image_id).inspect}}")
                    end
                    # Find the first customization template that matches the template name if none was chosen in the dialog
                    if prov.get_option(:customization_template_id).nil?
                      log(:info, "Inspecting Eligible Customization Templates: #{prov.eligible_customization_templates.inspect}")
                      cust_temp = prov.eligible_customization_templates.detect { |ct| ct.name.casecmp(template.name) == 0 }
                      if cust_temp.nil?
                        log(:error, "Failed to find matching PXE Image", true)
                        raise "Failed to find matching PXE Image"
                      end
                      log(:info, "Found mathcing Windows Customization Template ID: #{cust_temp.id} Name: #{cust_temp.name} Description: #{cust_temp.description}")
                      prov.set_customization_template(cust_temp)
                      log(:info, "Provisioning object updated {:customization_template_id => #{prov.get_option(:customization_template_id).inspect}}")
                    end
                  elsif @mapping == 1
                    # find the first PXE Image that matches the template name if NOT chosen in the dialog
                    if prov.get_option(:pxe_image_id).nil?
                      pxe_image = prov.eligible_pxe_images.detect { |pi| pi.name.casecmp(template.name) == 0 }
                      log(:info, "Found Linux PXE Image ID: #{pxe_image.id}  Name: #{pxe_image.name} Description: #{pxe_image.description}")
                      prov.set_pxe_image(pxe_image)
                      log(:info, "Provisioning object updated {:pxe_image_id => #{prov.get_option(:pxe_image_id).inspect}}")
                    end
                    # Find the first Customization Template that matches the template name if NOT chosen in the dialog
                    if prov.get_option(:customization_template_id).nil?
                      cust_temp = prov.eligible_customization_templates.detect { |ct| ct.name.casecmp(template.name) == 0 }
                      log(:info, "Found Customization Template ID: #{cust_temp.id} Name: #{cust_temp.name} Description: #{cust_temp.description}")
                      prov.set_customization_template(cust_temp)
                      log(:info, "Provisioning object updated {:customization_template_id => #{prov.get_option(:customization_template_id).inspect}}")
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
end

ManageIQ::Automate::Infrastructure::VM::Provisioning::StateMachines::Methods::VMwareCustomizeRequest.new.main
