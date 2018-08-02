#
# Description: This method starts a synchronous refresh and save the
#              task id in the state variables so we can use it when
#              waiting for the refresh to finish.
#

module ManageIQ
  module Automate
    module System
      module Event
        module StateMachines
          module Refresh
            class TargetRefresh
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                task_id = event.refresh(refresh_target, true)
                raise "Refresh task not created" if task_id.blank?
                @handle.set_state_var(:refresh_task_id, task_id)
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

              def refresh_target
                @handle.object["refresh_target"].tap do |target|
                  @handle.log(:info, "Refresh target: [#{target}]")
                  raise "Refresh target not found" if target.nil?
                end
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::System::Event::StateMachines::Refresh::TargetRefresh.new.main
