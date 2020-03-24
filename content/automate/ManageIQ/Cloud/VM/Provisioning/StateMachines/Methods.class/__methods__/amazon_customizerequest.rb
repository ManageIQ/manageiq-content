#
# Description: This method is used to Customize the Amazon Provisioning Request
#

module ManageIQ
  module Automate
    module Cloud
      module VM
        module Provisioning
          module StateMachines
            module Methods
              class AmazonCustomizeRequest
                def initialize(handle = $evm)
                  @handle = handle
                  @mapping = false
                end

                def main
                  log(:info, "Provision:<#{prov.id}> Request:<#{prov.miq_provision_request.id}> Type:<#{prov.type}>")
                  log(:info, "Template: #{template.name} Provider: #{provider.name} Vendor: #{template.vendor} Product: #{product}")
                  log(:info, "Processing Amazon customizations...", true)
                  process_customization if @mapping
                  log(:info, "Processing Amazon customizations...Complete", true)
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

                def process_customization
                  set_options
                  set_customization_template
                end

                def set_options
                  if prov.get_option(:instance_type).nil? && ws_values.key?(:instance_type)
                    provider.flavors.each do |flavor|
                      if flavor.name.downcase == ws_values[:instance_type].downcase
                        prov.set_option(:instance_type, [flavor.id, "#{flavor.name}':'#{flavor.description}"])
                        log(:info, "Provisioning object updated {:instance_type => #{prov.get_option(:instance_type).inspect}}")
                      end
                    end
                  end

                  if prov.get_option(:guest_access_key_pair).nil? && ws_values.key?(:guest_access_key_pair)
                    provider.key_pairs.each do |keypair|
                      if keypair.name == ws_values[:guest_access_key_pair]
                        prov.set_option(:guest_access_key_pair, [keypair.id, keypair.name])
                        log(:info, "Provisioning object updated {:guest_access_key_pair => #{prov.get_option(:guest_access_key_pair).inspect}}")
                      end
                    end
                  end

                  if prov.get_option(:security_groups).blank? && ws_values.key?(:security_groups)
                    provider.security_groups.each do |securitygroup|
                      if securitygroup.name == ws_values[:security_groups]
                        prov.set_option(:security_groups, [securitygroup.id])
                        log(:info, "Provisioning object updated {:security_groups => #{prov.get_option(:security_groups).inspect}}")
                      end
                    end
                  end
                end

                def set_customization_template
                  if prov.get_option(:customization_template_id).present?
                    log(:info, "Customization Template selected from dialog ID: %{id} Script: %{script}" % {
                      :id     => prov.get_option(:customization_template_id).inspect,
                      :script => prov.get_option(:customization_template_script).inspect
                    })
                    return
                  end

                  customization_template_search_by_function       = "#{prov.type}_#{prov.get_tags[:function]}"
                  customization_template_search_by_template_name  = template.name
                  customization_template_search_by_ws_values      = ws_values[:customization_template]
                  log(:info, "prov.eligible_customization_templates: #{prov.eligible_customization_templates.inspect}")
                  customization_template = nil

                  unless customization_template_search_by_function.nil?
                    # Search for customization templates enabled for Cloud-Init that equal MiqProvisionAmazon_prov.get_tags[:function]
                    if customization_template.blank?
                      log(:info, "Searching for customization templates (Cloud-Init) enabled that are named: %{function}" % {
                        :function => customization_template_search_by_function
                      })
                      customization_template = prov.eligible_customization_templates.detect do |ct|
                        ct.name.casecmp(customization_template_search_by_function) == 0
                      end
                    end
                  end
                  unless customization_template_search_by_template_name.nil?
                    # Search for customization templates enabled for Cloud-Init that match the template/image name
                    if customization_template.blank?
                      log(:info, "Searching for customization templates (Cloud-Init) enabled that are named: %{name}" % {
                        :name => customization_template_search_by_template_name
                      })
                      customization_template = prov.eligible_customization_templates.detect do |ct|
                        ct.name.casecmp(customization_template_search_by_template_name) == 0
                      end
                    end
                  end
                  unless customization_template_search_by_ws_values.nil?
                    # Search for customization templates enabled for Cloud-Init that match ws_values[:customization_template]
                    if customization_template.blank?
                      log(:info, "Searching for customization templates (Cloud-Init) enabled that are named: %{ws_value}" % {
                        :ws_value => customization_template_search_by_ws_values
                      })
                      customization_template = prov.eligible_customization_templates.detect do |ct|
                        ct.name.casecmp(customization_template_search_by_ws_values) == 0
                      end
                    end
                  end
                  if customization_template.blank?
                    log(:warn, "Failed to find matching Customization Template", true)
                  else
                    log(:info, "Found Customization Template ID: %{id} Name: %{name} Description: %{desc}" % {
                      :id   => customization_template.id,
                      :name => customization_template.name,
                      :desc => customization_template.description
                    })
                    prov.set_customization_template(customization_template) rescue nil
                    log(:info, "Provisioning object updated {:customization_template_id => %{id}}" % {
                      :id => prov.get_option(:customization_template_id).inspect
                    })
                    log(:info, "Provisioning object updated {:customization_template_script => %{script}}" % {
                      :script => prov.get_option(:customization_template_script).inspect
                    })
                  end
                end

                def log(level, msg, update_message = false)
                  @handle.log(level, msg)
                  @handle.root['miq_provision'].message = msg if @handle.root['miq_provision'] && update_message
                end
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Cloud::VM::Provisioning::StateMachines::Methods::AmazonCustomizeRequest.new.main
