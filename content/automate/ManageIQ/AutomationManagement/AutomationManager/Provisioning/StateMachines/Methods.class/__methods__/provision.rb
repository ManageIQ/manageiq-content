#
# Description: Trigger internal state machine that performs the actual provisioning.
#
module ManageIQ
  module Automate
    module AutomationManagement
      module AutomationManager
        module Provisioning
          module StateMachines
            module Methods
              class Provision
                def initialize(handle = $evm)
                  @handle = handle
                end

                def main
                  @handle.root['miq_provision_task'].execute
                end
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::AutomationManagement::AutomationManager::Provisioning::StateMachines::Methods::Provision.new.main
