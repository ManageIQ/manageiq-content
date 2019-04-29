#
# Description: Trigger internal state machine that performs the actual provisioning.
#
module ManageIQ
  module Automate
    module PhysicalInfrastructure
      module PhysicalServer
        module Provisioning
          module StateMachines
            module Methods
              class Provision
                def initialize(handle = $evm)
                  @handle = handle
                end

                def main
                  @handle.root['physical_server_provision_task'].execute
                end
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::PhysicalInfrastructure::PhysicalServer::Provisioning::StateMachines::Methods::Provision.new.main
