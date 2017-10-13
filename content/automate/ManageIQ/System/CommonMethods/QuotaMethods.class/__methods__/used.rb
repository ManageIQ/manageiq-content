# frozen_string_literal: true
#
# Description: calculate entity used quota values
#

module ManageIQ
  module Automate
    module System
      module CommonMethods
        module QuotaMethods
          class Used
            def initialize(handle = $evm)
              @handle = handle
            end

            def main
              used(quota_source)
            end

            private

            def used(quota_source)
              quota_used = consumption(quota_source)
              @handle.log("info", "Quota Used: #{quota_used.inspect}")

              quota_active = active_provision_counts
              @handle.log("info", "Quota #{active_method_name}: #{quota_active.inspect}")

              merge_counts(quota_used, quota_active)
            end

            def quota_source
              raise "ERROR - quota_source not found" unless @handle.root['quota_source']
              @handle.root['quota_source']
            end

            def consumption(source)
              {
                :cpu                 => source.allocated_vcpu,
                :memory              => source.allocated_memory,
                :vms                 => source.vms.count { |vm| vm.id unless vm.archived },
                :storage             => source.allocated_storage,
                :provisioned_storage => source.provisioned_storage
              }
            end

            def active_method_name
              quota_source = @handle.root['quota_source_type'].downcase
              source = quota_source == 'user' ? 'owner' : quota_source
              "active_provisions_by_#{source}".to_sym
            end

            def active_provision_counts
              active_provisions = @handle.root['miq_request'].check_quota(active_method_name)
              {:cpu                 => active_provisions[:cpu],
               :memory              => active_provisions[:memory],
               :vms                 => active_provisions[:count],
               :storage             => active_provisions[:storage],
               :provisioned_storage => 0}
            end

            def merge_counts(quota_used, quota_active)
              @handle.root['quota_used'] = quota_used.merge(quota_active) { |_key, val1, val2| val1 + val2 }
              @handle.log("info", "Quota Totals: #{@handle.root['quota_used'].inspect}")
            end
          end
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  ManageIQ::Automate::System::CommonMethods::QuotaMethods::Used.new.main
end
