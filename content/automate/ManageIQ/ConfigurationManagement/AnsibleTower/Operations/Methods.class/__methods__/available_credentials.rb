#
# Description: provide the dynamic list content from available credentials
# for Ansible Provider
#
module ManageIQ
  module Automate
    module ConfigurationManagement
      module AnsibleTower
        module Operations
          class AvailableCredentials
            def initialize(handle = $evm)
              @handle = handle
            end

            def main
              fill_dialog_field(fetch_list_data)
            end

            private
            
            def get_provider
              # for provisioning we use     service_template
              # for reconfig and retire use service
              service = @handle.root['service_template'] || @handle.root['service']
              service.try(:provision).try(:job_template).try(:ems_ref)
            end

            def fetch_list_data
              credentials = get_provider.try(:authentications) || []
              credential_list = {}
              credentials.each do |credential|
                  credential_list[credential.id] = credential.name || "unknown"
              end
              return nil => "<none>" if credential_list.blank?
              credential_list[nil] = "<select>" if credential_list.length > 1
              credential_list
            end

            def fill_dialog_field(list)
              dialog_field = @handle.object

              # sort_by: value / description / none
              dialog_field["sort_by"] = "value"

              # sort_order: ascending / descending
              dialog_field["sort_order"] = "ascending"

              # data_type: string / integer
              dialog_field["data_type"] = "string"

              # required: true / false
              dialog_field["required"] = "true"

              dialog_field["values"] = list
              dialog_field["default_value"] = list.length == 1 ? list.keys.first : nil
            end
          end
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  ManageIQ::Automate::ConfigurationManagement::AnsibleTower::Operations::AvailableCredentials.new.main
end
