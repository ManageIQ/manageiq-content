#
# Description: provide the dynamic list content from available flavors
#
module ManageIQ
  module Automate
    module Cloud
      module Orchestration
        module Operations
          class AvailableFlavors
            def initialize(handle = $evm)
              @handle = handle
            end

            def main
              fill_dialog_field(fetch_list_data)
            end

            private

            def orchestration_manager_from_bundle(service)
              service.service_templates.detect(&:orchestration_manager).try(:orchestration_manager) if service.respond_to?(:service_templates)
            end

            def fetch_list_data
              service = @handle.root.attributes["service_template"] || @handle.root.attributes["service"]

              orch_mgr = service.try(:orchestration_manager) || orchestration_manager_from_bundle(service)
              flavors = orch_mgr.try(:flavors)
              flavor_list = {}
              flavors.each { |f| flavor_list[f.name] = f.name } if flavors

              return nil => "<none>" if flavor_list.blank?

              flavor_list[nil] = "<select>" if flavor_list.length > 1
              flavor_list
            end

            def fill_dialog_field(list)
              dialog_field = @handle.object

              # sort_by: value / description / none
              dialog_field["sort_by"] = "description"

              # sort_order: ascending / descending
              dialog_field["sort_order"] = "ascending"

              # data_type: string / integer
              dialog_field["data_type"] = "string"

              # required: true / false
              dialog_field["required"] = "true"

              dialog_field["values"] = list
              dialog_field["default_value"] = nil
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Cloud::Orchestration::Operations::AvailableFlavors.new.main
