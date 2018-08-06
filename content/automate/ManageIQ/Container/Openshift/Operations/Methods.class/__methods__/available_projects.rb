#
# Description: provide the dynamic list content from available flavors
#
module ManageIQ
  module Automate
    module Container
      module Openshift
        module Operations
          class AvailableProjects
            def initialize(handle = $evm)
              @handle = handle
            end

            def main
              fill_dialog_field(fetch_list_data)
            end

            private

            def fetch_list_data
              service = @handle.root.attributes["service_template"] || @handle.root.attributes["service"]
              projects = service.try(:container_manager).try(:container_projects)

              project_list = {}
              projects.each { |p| project_list[p.name] = p.name } if projects

              return nil => "<none>" if project_list.blank?

              project_list[nil] = "<select>" if project_list.length > 1
              project_list
            end

            def fill_dialog_field(list)
              dialog_hash = {
                'sort_by'       => "description",
                'data_type'     => "string",
                'required'      => false,
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

ManageIQ::Automate::Container::Openshift::Operations::AvailableProjects.new.main
