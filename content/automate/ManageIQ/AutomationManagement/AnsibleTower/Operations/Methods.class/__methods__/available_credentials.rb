#
# Description: provide the dynamic list content from available credentials
# for Ansible Provider
#
module ManageIQ
  module Automate
    module AutomationManagement
      module AnsibleTower
        module Operations
          class AvailableCredentials
            AUTH_CLASS = "ManageIQ_Providers_AutomationManager_Authentication".freeze
            EMBEDDED_ANSIBLE_CLASS = "ManageIQ_Providers_EmbeddedAnsible_AutomationManager".freeze
            def initialize(handle = $evm)
              @handle = handle
            end

            def main
              fill_dialog_field(fetch_list_data)
            end

            private

            def provider
              # for provisioning we use     service_template
              # for reconfig and retire use service
              # Or use the embedded_ansible_provider
              service = @handle.root['service_template'] || @handle.root['service']
              service.try(:job_template, 'Provision').try(:manager) || embedded_ansible_provider
            end

            def embedded_ansible_provider
              @handle.vmdb(EMBEDDED_ANSIBLE_CLASS).first if @handle.inputs.fetch('embedded_ansible', false)
            end

            def credentials
              @handle.vmdb(AUTH_CLASS).where("resource_id = ? AND type = ?",
                                             provider.try(:id),
                                             @handle.inputs['credential_type'])
            end

            def fetch_list_data
              credential_list = Hash[*credentials.pluck(:id, :name).flatten]
              @handle.log(:debug, "Number of credentials found #{credential_list.count}")
              {nil => '<Default>'}.merge(credential_list)
            end

            def fill_dialog_field(list)
              dialog_hash = {
                'sort_by'       => "description",
                'data_type'     => "string",
                'required'      => false,
                'sort_order'    => "ascending",
                'values'        => list,
                'default_value' => nil
              }

              dialog_hash.each { |key, value| @handle.object[key] = value }
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::AutomationManagement::AnsibleTower::Operations::AvailableCredentials.new.main
