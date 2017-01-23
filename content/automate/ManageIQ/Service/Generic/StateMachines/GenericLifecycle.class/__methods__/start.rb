#
# Description: This method creates a starting notification
#
module ManageIQ
  module Automate
    module Service
      module Generic
        module StateMachines
          module GenericLifecycle
            class Start
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                @handle.log('info', "State Machine Starting")
                $evm.create_notification(:level => 'info', :message => "Starting")
              end
            end
          end
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  ManageIQ::Automate::Service::Generic::StateMachines::GenericLifecycle::Start.new.main
end
