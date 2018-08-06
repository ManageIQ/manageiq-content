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
                check_status(refresh_task)
              end

              private

              def check_status(task)
                case task.state
                when STATE_FINISHED
                  if task.status == STATUS_OK
                    @handle.root['ae_result'] = 'ok'
                  else
                    @handle.root['ae_result'] = 'error'
                    @handle.log(:error, "Refresh task ended with error: #{task.message}")
                  end
                else
                  @handle.root['ae_result'] = 'retry'
                  @handle.root['ae_retry_interval'] = '1.minute'
                end
              end

              def refresh_task
                task_id = @handle.get_state_var(:refresh_task_id).first
                @handle.log(:info, "Stored refresh task ID: [#{task_id}]")
                fetch_task(task_id)
              end

              def fetch_task(task_id)
                @handle.vmdb(:miq_task).find_by(:id => task_id).tap do |task|
                  if task.nil?
                    @handle.log(:error, "Refresh task with id: #{task_id} not found")
                    raise "Refresh task with id: #{task_id} not found"
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
