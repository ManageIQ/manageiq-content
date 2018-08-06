module ManageIQ
  module Automate
    module System
      module Event
        module EmsEvent
          module RHEVM
            class UpdateVmImportStatus
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                update_import_status(vm)
              end

              private

              def vm_id
                event_stream = @handle.root['event_stream']
                if event_stream.nil?
                  @handle.log(:error, 'event_stream not found')
                  raise 'event_stream not found'
                end
                event_stream.vm_or_template_id
              end

              def vm
                @handle.vmdb('Vm', vm_id).tap do |vm|
                  if vm.nil?
                    @handle.log(:error, 'VM object not found')
                    raise 'VM object not found'
                  end
                end
              end

              def import_status
                @handle.root['event_type'] == 'IMPORTEXPORT_IMPORT_VM_FAILED' ? 'failure' : 'success'
              end

              def update_import_status(vm)
                @handle.log(:info, "Updating VM [#{vm.name}] import status to [#{import_status}]")
                vm.custom_set(:import_status, import_status)
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::System::Event::EmsEvent::RHEVM::UpdateVmImportStatus.new.main
