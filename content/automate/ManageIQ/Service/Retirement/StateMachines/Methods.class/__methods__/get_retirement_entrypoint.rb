# frozen_string_literal: true

#
# Description: Resolves Service retirement entry point if present
#

module ManageIQ
  module Automate
    module Service
      module Retirement
        module StateMachines
          module Methods
            class GetRetirementEntrypoint
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                retirement_entrypoint
              end

              private

              def retirement_entrypoint
                if service
                  @handle.root['retirement_entry_point'] = entry_point
                  @handle.root['service_action'] = 'Retirement'
                  @handle.log("info", "retirement_entrypoint: #{entry_point}")
                end
              end

              def service
                svc = @handle.root['service']
                if svc.nil?
                  @handle.log('error', 'retirement_entrypoint: missing service object')
                  exit MIQ_ABORT
                end
                svc
              end

              def entry_point
                entry_point = service.automate_retirement_entrypoint
                if entry_point.blank?
                  entry_point = '/Service/Retirement/StateMachines/ServiceRetirement/Default'
                  @handle.log("info", "retirement_entrypoint not specified using default: #{entry_point}")
                end
                entry_point
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Service::Retirement::StateMachines::Methods::GetRetirementEntrypoint.new.main
