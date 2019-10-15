# frozen_string_literal: true

#
# Description: Get Quota Source
#
module ManageIQ
  module Automate
    module System
      module CommonMethods
        module QuotaMethods
          class QuotaSource
            def initialize(handle = $evm)
              @handle = handle
            end

            def main
              quota_source
            end

            private

            def miq_request
              @handle.root['miq_request']
            end

            def quota_source
              @handle.root['quota_source_type'] = @handle.object.parent['quota_source_type'] || @handle.object['quota_source_type']
              case @handle.root['quota_source_type'].downcase
              when 'group'
                @handle.root['quota_source'] = miq_request.requester.current_group
              when 'user'
                @handle.root['quota_source'] = miq_request.requester
              else
                @handle.root['quota_source'] = miq_request.tenant
                @handle.root['quota_source_type'] = 'tenant'
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::System::CommonMethods::QuotaMethods::QuotaSource.new.main
