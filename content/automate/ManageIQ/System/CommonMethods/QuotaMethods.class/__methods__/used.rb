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

              quota_source_type = root_quota_source_type
              @handle.log("info", "Quota source type: #{quota_source_type}")

              validate_user_email if quota_source_type == 'user'
              quota_active = active_provision_counts(quota_source_type)
              @handle.log("info", "Quota #{active_method_name(quota_source_type)}: #{quota_active.inspect}")

              merge_counts(quota_used, quota_active)
            end

            def quota_source
              raise "ERROR - quota_source not found" unless @handle.root['quota_source']
              @handle.root['quota_source']
            end

            def root_quota_source_type
              raise "ERROR - quota_source_type not found" unless @handle.root['quota_source_type']
              @handle.root['quota_source_type'].downcase
            end

            def consumption(source)
              {
                :cpu                 => source.allocated_vcpu,
                :memory              => source.allocated_memory,
                :vms                 => source.vms.count { |vm| vm.id if vm.ems_id },
                :storage             => source.allocated_storage,
                :provisioned_storage => source.provisioned_storage
              }
            end

            def active_method_name(quota_source_type)
              source = quota_source_type == 'user' ? 'owner' : quota_source_type
              "active_provisions_by_#{source}".to_sym
            end

            def validate_user_email
              email = @handle.root['miq_request'].get_option(:owner_email) || @handle.root['miq_request'].requester.email
              return if email.present?
              @handle.log(:error, "Owner email not specified for User Quota")
              raise "ERROR - Owner email not specified for User Quota"
            end

            def active_provision_counts(quota_source_type)
              active_provisions = @handle.root['miq_request'].check_quota(active_method_name(quota_source_type))
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

ManageIQ::Automate::System::CommonMethods::QuotaMethods::Used.new.main
