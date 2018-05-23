module ManageIQ
  module Automate
    module Transformation
      module Infrastructure
        module VM
          module RedHat
            class CheckVmInInventory
              def initialize(handle = $evm)
                @handle = handle
              end
          
              def main
                begin
                  task = @handle.root['service_template_transformation_plan_task']
                  source_vm = task.source
                  destination_ems = task.transformation_destination(source_vm.ems_cluster).ext_management_system
                  destination_vm = ManageIQ::Automate::Transformation::Infrastructure::VM::RedHat::Utils.new(destination_ems).vm_find_by_name(source_vm.name)
                  raise "VM #{source_vm.name} not found in destination provider #{destination_ems.name}" if destination_vm.nil?
            
                  finished = false
            
                  destination_vm_vmdb = @handle.vmdb(:vm).where(["ems_ref = ?", destination_vm.href.gsub(/^\/ovirt-engine/, '')]).first
                  if destination_vm_vmdb.blank?
                    @handle.log(:info, "VM '#{source_vm.name}' not found in VMDB.")
                    if @handle.state_var_exist?(:ems_refresh_in_progress)
                      @handle.log(:info, "Refresh of '#{destination_ems.name}' is in progress. Nothing to do.")
                    else
                      @handle.log(:info, "Forcing refresh of provider '#{destination_ems.name}'")
                      destination_ems.refresh
                      @handle.set_state_var(:ems_refresh_in_progress, true)
                    end
                  else
                    @handle.log(:info, "VM '#{source_vm.name}' found in VMDB with id '#{destination_vm_vmdb.id}'")
                    task.set_option(:destination_vm_id, destination_vm_vmdb.id)
                    finished = true
                  end
            
                  unless finished
                    @handle.root['ae_result'] = 'retry'
                    @handle.root['ae_retry_interval'] = '15.seconds'
                  end
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
  ManageIQ::Automate::Transformation::Infrastructure::VM::RedHat::CheckVmInInventory.new.main
end
