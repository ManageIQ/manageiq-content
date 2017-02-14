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
              service.try(:job_template, 'Provision').try(:manager)
            end 

            def get_credentials
              credentials = get_provider.try(:credentials) || []
              credentials.select { |c| c.type == @handle.inputs['credential_type'] }
            end
            
            def fetch_list_data
              credential_list = Hash[*get_credentials.pluck(:id, :name).flatten]
              @handle.log(:info, "Number of credentials found #{credential_list.keys.count}")
              return nil => "<none>" if credential_list.blank?
              credential_list[nil] = "<select>" if credential_list.length > 1
              credential_list
            end

            def fill_dialog_field(list)
              dialog_hash = {
                'sort_by'       => "value",
                'data_type'     => "string",
                'required'      => true,
                'sort_order'    => "ascending",
                'values'        => list,
                'default_value' => list.length == 1 ? list.keys.first : nil
              }

              dialog_hash.each { |key, value| @handle.object[key] = value }
            end
          end
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  ManageIQ::Automate::AutomationManagement::AnsibleTower::Operations::AvailableCredentials.new.main
end
