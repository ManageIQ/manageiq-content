# frozen_string_literal: true

#
# Description: Quota Exceeded rejected method.
#
module ManageIQ
  module Automate
    module System
      module CommonMethods
        module QuotaStateMachine
          class Rejected
            def initialize(handle = $evm)
              @handle = handle
            end

            def main
              rejected
            end

            private

            def rejected
              request = @handle.root['miq_request']
              @handle.log('info', "Request denied because of #{request.message}")
              request.deny('admin', 'Quota Exceeded')

              @handle.create_notification(:level => 'error', :subject => request, :message => "Quota Exceeded: #{request.message}")
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::System::CommonMethods::QuotaStateMachine::Rejected.new.main
