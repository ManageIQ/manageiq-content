#
# Description: This method checks the refresh completion.
#

module ManageIQ
  module Automate
    module System
      module Event
        module StateMachines
          module Refresh
            class CheckRefreshed
              STATE_FINISHED = 'Finished'.freeze
              STATUS_OK = 'Ok'.freeze

              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                if event.ext_management_system.last_inventory_date >= event.timestamp
                  @handle.root['ae_result'] = 'ok'
                else
                  @handle.root['ae_result'] = 'retry'
                  @handle.root['ae_retry_interval'] = '1.minute'
                end
              end

              private

              def event
                @handle.root["event_stream"].tap do |event|
                  if event.nil?
                    @handle.log(:error, 'Event object is nil')
                    raise 'Event object not found'
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::System::Event::StateMachines::Refresh::CheckRefreshed.new.main
