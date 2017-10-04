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
              @handle.root['quota_used'] = consumption(quota_source)
            end

            def quota_source
              raise "ERROR - quota_source not found" unless @handle.root['quota_source']
              @handle.root['quota_source']
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
          end
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  ManageIQ::Automate::System::CommonMethods::QuotaMethods::Used.new.main
end
