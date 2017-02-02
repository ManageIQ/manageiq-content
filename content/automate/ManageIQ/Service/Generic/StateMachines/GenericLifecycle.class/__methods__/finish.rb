#
# Description: This method created a notification
#
module ManageIQ
  module Automate
    module Service
      module Generic
        module StateMachines
          module GenericLifecycle
            class Finish
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                @handle.log("info", "finish starting")

                @handle.log("info", "finish ending")
              end
            end
          end
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  ManageIQ::Automate::Service::Generic::StateMachines::GenericLifecycle::Finish.new.main
end
