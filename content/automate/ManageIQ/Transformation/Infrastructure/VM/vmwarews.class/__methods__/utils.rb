module ManageIQ
  module Automate
    module Transformation
      module Infrastructure
        module VM
          module VMware
            class Utils
              require 'rbvmomi'
          
              def initialize(handle = $evm)
                @handle = handle
              end
          
              def main
              end
          
              def connect_to_provider(ems)
                ipaddress = ems.ipaddress
                ipaddress ||= ems.hostname
                RbVmomi::VIM.connect(host: ipaddress, user: ems.authentication_userid, password: ems.authentication_password, insecure: true)
              end
          
              def vm_get_ref(vim, vm)
                dc = vim.serviceInstance.find_datacenter(vm.v_owning_datacenter)
                raise "Datacenter '#{vm.datacenter.name}' not found in vCenter" unless dc
                vim.serviceInstance.content.searchIndex.FindByUuid(datacenter: dc, uuid: vm.uid_ems, vmSearch: true, instanceUuid: false)
              end
          
              def self.get_vcenter_fingerprint(ems, handle=$evm)
                command = "openssl s_client -connect #{ems.hostname}:443 2>\/dev\/null | openssl x509 -noout -fingerprint -sha1"
                ssl_fingerprint = `#{command}`
                fingerprint = ssl_fingerprint[17..ssl_fingerprint.size-2]
                handle.log(:info, "vCenter fingerprint: #{fingerprint}")
                return fingerprint
              end
          
              def self.vm_rename_bill(vm, new_name, handle=$evm)
                ems = vm.ext_management_system
                ems_endpoint = ems.ipaddress || ems.hostname
                vim = RbVmomi::VIM.connect(host: ems_endpoint, user: ems.authentication_userid, password: ems.authentication_password, insecure: true)
                vm_ref = vm_get_ref(vim, vm)
            
                spec = RbVmomi::VIM::VirtualMachineConfigSpec(name: new_name)
                task = vm_ref.ReconfigVM_Task(spec: spec)
            
                # Seems using the task.info.state returned by the ReconfigVM_Task is not trust worthy. It will return 'state' = 'running'
                # and the later polls by the taskManager returns 'error', 'Another task is already in progress'...
                # ...so lets wait for 5 seconds and ask then task manager what it thinks the real state is.
                handle.log(:info, "task.info.state = #{task.info.state}")
                handle.log(:info, "task.info.error.localMessage = #{task.info.error.localizedMessage}") if task.info.state == 'error'
            
                sleep(5)
                tm = vim.serviceInstance.content.taskManager
                tasks = tm.recentTask.select { |t| t.info.key ==  task.info.key }
                raise "Cannot find task key #{task.info.key} in vCenter" unless tasks.any?
                task = tasks.first
            
                handle.log(:info, "task manager says: task.info.state = #{task.info.state}")
                handle.log(:info, "task manager says: task.info.error.localMessage = #{task.info.error.localizedMessage}") if task.info.state == 'error'
            
                if task.info.state == 'error'
                  raise "Delete disk error: #{task.info.error.localizedMessage}" unless task.info.error.localizedMessage.include?('Another task is already in progress')
                  handle.log(:info, "Delete disk cannot start due to another vCenter task running, Will retry in 30 seconds")
                  handle.root['ae_result'] = 'retry'
                  handle.root['ae_retry_interval'] = '30.seconds'
                end
                true
              end
              
              def self.vm_rename(vm, new_name, handle = $evm)
                ems = vm.ext_management_system
                ems_endpoint = ems.ipaddress || ems.hostname
                vim = RbVmomi::VIM.connect(host: ems_endpoint, user: ems.authentication_userid, password: ems.authentication_password, insecure: true)
                
                sleep 2
                dc = vim.serviceInstance.find_datacenter(vm.v_owning_datacenter)
                raise "Datacenter '#{vm.v_owning_datacenter}' not found in vCenter" unless dc

                sleep 2
                vim_vm = dc.find_vm(vm.name)
                raise "Unable to locate #{vm.name} in data center #{dc}"
                begin
                  sleep 2
                  vim_vm.ReconfigVM_Task(:spec => RbVmomi::VIM::VirtualMachineConfigSpec(:name=> new_name)).wait_for_completion
                  sleep 2
                  dc.find_vm(new_name)
                  puts "Successfully renamed #{options[:source_vm]} to #{options[:new_name]}."
                rescue
                  return false
                end
                true
              end
              
            end
          end
        end
      end
    end
  end
end
