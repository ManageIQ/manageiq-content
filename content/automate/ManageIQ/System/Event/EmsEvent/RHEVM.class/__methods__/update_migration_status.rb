module ManageIQ
  module Automate
    module System
      module Event
        module EmsEvent
          module RHEVM
            class UpdateMigrationStatus
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                update_migration_status(vm)
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

              def migration_status
                @handle.root['event_type'] == 'VM_MIGRATION_FAILED_FROM_TO' ? 'failure' : 'success'
              end

              def update_migration_status(vm)
                @handle.log(:info, "Updating VM [#{vm.name}] migration status to [#{migration_status}]")
                vm.set_migration_status(migration_status)
              end
            end
          end
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  ManageIQ::Automate::System::Event::EmsEvent::RHEVM::UpdateMigrationStatus.new.main
end
