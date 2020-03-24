#
# Description: This method is used to Customize the Provisioning Request
# Customization Template mapping for RHEV, RHEV PXE, and RHEV ISO provisioning
#

module ManageIQ
  module Automate
    module Infrastructure
      module VM
        module Provisioning
          module StateMachines
            module Methods
              class RedhatCustomizeRequest
                def initialize(handle = $evm)
                  @handle = handle
                  @mapping = false
                end

                def main
                  log(:info, "Provision:<#{prov.id}> Request:<#{prov.miq_provision_request.id}> Type:<#{prov.type}>")
                  log(:info, "Template: #{template.name} Provider: #{provider.name} Vendor: #{template.vendor} Product: #{product}")
                  # Build case statement to determine which type of processing is required
                  case prov.type
                  when 'ManageIQ::Providers::Redhat::InfraManager::Provision'
                    process_redhat if @mapping
                  when 'ManageIQ::Providers::Redhat::InfraManager::ProvisionViaIso'
                    process_redhat_iso if @mapping
                  when 'ManageIQ::Providers::Redhat::InfraManager::ProvisionViaPxe'
                    process_redhat_pxe if @mapping
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

                def ws_values
                  @ws_values ||= prov.options.fetch(:ws_values, {})
                end

                def log(level, msg, update_message = false)
                  @handle.log(level, msg)
                  @handle.root['miq_provision'].message = msg if @handle.root['miq_provision'] && update_message
                end

                def process_redhat_pxe
                  if product.include?("windows")
                    # find the windows image that matches the template name if a PXE Image was NOT chosen in the dialog
                    if prov.get_option(:pxe_image_id).nil?

                      log(:info, "Inspecting prov.eligible_windows_images: #{prov.eligible_windows_images.inspect}")
                      pxe_image = prov.eligible_windows_images.detect { |pi| pi.name.casecmp(template.name) == 0 }
                      if pxe_image.nil?
                        msg = "Failed to find matching PXE Image"
                        log(:error, msg, true)
                        raise msg
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
                        msg = "Failed to find matching PXE Image"
                        log(:error, msg, true)
                        raise msg
                      end
                      log(:info, "Found matching Windows Customization Template ID: #{cust_temp.id} Name: #{cust_temp.name} Description: #{cust_temp.description}")
                      prov.set_customization_template(cust_temp)
                      log(:info, "Provisioning object updated {:customization_template_id => #{prov.get_option(:customization_template_id).inspect}}")
                    end
                  else
                    # find the first PXE Image that matches the template name if NOT chosen in the dialog
                    if prov.get_option(:pxe_image_id).nil?
                      pxe_image = prov.eligible_pxe_images.detect { |pi| pi.name.casecmp(template.name) == 0 }
                      log(:info, "Found Linux PXE Image ID: #{pxe_image.id} Name: #{pxe_image.name} Description: #{pxe_image.description}")
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

                # process_redhat_iso - mapping customization templates (ks.cfg)
                def process_redhat_iso
                  if product.include?("windows")
                    # Linux Support only for now
                  else
                    # Linux - Find the first ISO Image that matches the template name if NOT chosen in the dialog
                    if prov.get_option(:iso_image_id).nil?
                      log(:info, "Inspecting prov.eligible_iso_images: #{prov.eligible_iso_images.inspect}")
                      iso_image = prov.eligible_iso_images.detect { |iso| iso.name.casecmp(template.name) == 0 }
                      if iso_image.nil?
                        msg = "Failed to find matching ISO Image"
                        log(:error, msg, true)
                        raise msg
                      else
                        log(:info, "Found Linux ISO Image ID: #{iso_image.id} Name: #{iso_image.name}")
                        prov.set_iso_image(iso_image)
                        log(:info, "Provisioning object updated {:iso_image_id => #{prov.get_option(:iso_image_id).inspect}}")
                      end
                    else
                      log(:info, "ISO Image selected from dialog: #{prov.get_option(:iso_image_id).inspect}")
                    end

                    # Find the first Customization Template that matches the template name if NOT chosen in the dialog
                    if prov.get_option(:customization_template_id).nil?
                      log(:info, "prov.eligible_customization_templates: #{prov.eligible_customization_templates.inspect}")

                      cust_temp = prov.eligible_customization_templates.detect { |ct| ct.name.casecmp(template.name) == 0 }
                      if cust_temp.nil?
                        msg = "Failed to find matching Customization Template"
                        log(:error, msg, true)
                        raise msg
                      else
                        log(:info, "Found Customization Template ID: #{cust_temp.id} Name: #{cust_temp.name} Description: #{cust_temp.description}")
                        prov.set_customization_template(cust_temp)
                        log(:info, "Provisioning object updated {:customization_template_id => #{prov.get_option(:customization_template_id).inspect}}")
                      end
                    else
                      log(:info, "Customization Template selected from dialog: #{prov.get_option(:customization_template_id).inspect}")
                    end
                  end
                end

                # process_redhat - mapping cloud-init templates
                def process_redhat
                  log(:info, "Processing process_redhat...", true)
                  if prov.get_option(:customization_template_id).nil?
                    customization_template_search_by_ws_values = ws_values[:customization_template]
                    customization_template_search_by_template_name = template.name
                    log(:info, "prov.eligible_customization_templates: #{prov.eligible_customization_templates.inspect}")
                    customization_template = nil

                    unless customization_template_search_by_template_name.nil?
                      # Search for customization templates enabled for Cloud-Init that match the template/image name
                      if customization_template.blank?
                        log(:info, "Searching for customization templates enabled for (Cloud-Init) that are named: #{customization_template_search_by_template_name}")
                        customization_template = prov.eligible_customization_templates.detect { |ct| ct.name.casecmp(template.name) == 0 }
                      end
                    end
                    unless customization_template_search_by_ws_values.nil?
                      # Search for customization templates enabled for Cloud-Init that match ws_values[:customization_template]
                      if customization_template.blank?
                        log(:info, "Searching for customization templates enabled for (Cloud-Init) that are named: #{customization_template_search_by_ws_values}")
                        customization_template = prov.eligible_customization_templates.detect { |ct| ct.name.casecmp(customization_template_search_by_ws_values) == 0 }
                      end
                    end
                    if customization_template.blank?
                      log(:warn, "Failed to find matching Customization Template", true)
                    else
                      log(:info, "Found Customization Template ID: #{customization_template.id} Name: #{customization_template.name} Description: #{customization_template.description}")
                      prov.set_customization_template(customization_template) rescue nil
                      log(:info, "Provisioning object updated {:customization_template_id => #{prov.get_option(:customization_template_id).inspect}}")
                      log(:info, "Provisioning object updated {:customization_template_script => #{prov.get_option(:customization_template_script).inspect}}")
                    end
                  else
                    log(:info, "Customization Template selected from dialog ID: #{prov.get_option(:customization_template_id).inspect} Script: #{prov.get_option(:customization_template_script).inspect}")
                  end
                  log(:info, "Processing process_redhat...Complete", true)
                end
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Infrastructure::VM::Provisioning::StateMachines::Methods::RedhatCustomizeRequest.new.main
