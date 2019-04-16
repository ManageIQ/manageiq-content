#
# Description: <Method description here>
#
module ManageIQ
  module Automate
    module PhysicalInfrastructure
      module PhysicalServer
        module Provisioning
          module StateMachines
            module Methods
              class CheckProvision
                def initialize(handle = $evm)
                  @handle = handle
                end

                def main
                  task = @handle.root["physical_server_provision_task"]
                  result = task.statemachine_task_status
                  server = task.source
                  server_str = "PhysicalServer id=#{server.id} ems_ref=#{server.ems_ref}"

                  @handle.log('info', "ProvisionCheck (#{server_str}) returned <#{result}> for state <#{task.state}> and status <#{task['status']}>")

                  case result
                  when 'error'
                    @handle.root['ae_result'] = 'error'
                    @handle.root['ae_reason'] = task.message.sub('Error: ', '')
                    @handle.log('error', "ProvisionCheck (#{server_str}) error <#{task.message}>")
                  when 'retry'
                    @handle.root['ae_result'] = 'retry'
                    @handle.root['ae_retry_interval'] = '1.minute'
                  when 'ok'
                    @handle.root['ae_result'] = 'ok'
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

ManageIQ::Automate::PhysicalInfrastructure::PhysicalServer::Provisioning::StateMachines::Methods::CheckProvision.new.main
