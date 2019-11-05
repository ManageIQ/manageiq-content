#
# Description: This method removes the Service from the VMDB database
#

module ManageIQ
  module Automate
    module Service
      module Retirement
        module StateMachines
          module Methods
            class DeleteServiceFromVmdb
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                service = @handle.root['service']
                if service
                  @handle.log('info', "Deleting Service <#{service.name}> from VMDB")
                  service.remove_from_vmdb
                  @handle.root['service'] = nil
                end
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Service::Retirement::StateMachines::Methods::DeleteServiceFromVmdb.new.main
