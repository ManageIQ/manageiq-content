module ManageIQ
  module Automate
    module Transformation
      module Infrastructure
        module VM
          module VMware
            class SetMigrated
              def initialize(handle = $evm)
                @handle = handle
              end
          
              # Taken from / Service / Provisioning / StateMachines / Methods / configure_vm_hostname.
              def check_name_collisions(vm, new_name)
                name_collisions = Hash.new(0)
                @handle.vmdb(:vm).where("name = '#{new_name}'").each do |vm|
                  name_collisions[:active]   += 1 if vm.active
                  name_collisions[:template] += 1 if vm.template
                  name_collisions[:retired]  += 1 if vm.retired?
                  name_collisions[:archived] += 1 if vm.archived
                  name_collisions[:orphaned] += 1 if vm.orphaned
                end
                name_collisions_summary = ""
                name_collisions.each { |k, v| name_collisions_summary += " - #{k}: #{v}" }
                return name_collisions_summary
              end
          
              def main
                begin
                  exit MIQ_OK
                  task = @handle.root['service_template_transformation_plan_task']
                  source_vm = task.source
                  new_name = "#{source_vm.name}_migrated"
            
                  name_collisions = check_name_collisions(source_vm, new_name)
                  raise "ERROR: #{new_name} already exists #{name_collisions}." unless name_collisions.blank?
            
                  @handle.log(:info, "Renaming VM #{source_vm.name} to #{new_name}")
                  result = ManageIQ::Automate::Transformation::Infrastructure::VM::VMware::Utils.vm_rename(source_vm, new_name)
                  raise "VM rename for #{source_vm.name} to #{new_name} failed" unless result
                rescue Exception => e
                  @handle.set_state_var(:ae_state_progress, { 'message' => e.message })
                  raise
                end
              end
            end
          end
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  ManageIQ::Automate::Transformation::Infrastructure::VM::VMware::SetMigrated.new.main
end
