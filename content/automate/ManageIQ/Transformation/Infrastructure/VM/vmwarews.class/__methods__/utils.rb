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
                RbVmomi::VIM.connect(:host => ipaddress, :user => ems.authentication_userid, :password => ems.authentication_password, :insecure => true)
              end

              def vm_get_ref(vim, vm)
                dc = vim.serviceInstance.find_datacenter(vm.v_owning_datacenter)
                raise "Datacenter '#{vm.datacenter.name}' not found in vCenter" unless dc
                vim.serviceInstance.content.searchIndex.FindByUuid(:datacenter => dc, :uuid => vm.uid_ems, :vmSearch => true, :instanceUuid => false)
              end

              def self.host_fingerprint(host)
                command = "openssl s_client -connect #{host.ipaddress}:443 2>\/dev\/null | openssl x509 -noout -fingerprint -sha1"
                ssl_fingerprint = `#{command}`
                ssl_fingerprint[17..ssl_fingerprint.size - 2]
              end

              def self.vm_rename(vm, new_name, handle = $evm)
                ems = vm.ext_management_system
                ems_endpoint = ems.ipaddress || ems.hostname
                vim = RbVmomi::VIM.connect(:host => ems_endpoint, :user => ems.authentication_userid, :password => ems.authentication_password, :insecure => true)

                sleep 2
                dc = vim.serviceInstance.find_datacenter(vm.v_owning_datacenter)
                raise "Datacenter '#{vm.v_owning_datacenter}' not found in vCenter" unless dc

                sleep 2
                vim_vm = dc.find_vm(vm.name)
                raise "Unable to locate #{vm.name} in data center #{dc}" unless vim_vm
                begin
                  sleep 2
                  vim_vm.ReconfigVM_Task(:spec => RbVmomi::VIM::VirtualMachineConfigSpec(:name => new_name)).wait_for_completion
                  sleep 2
                  dc.find_vm(new_name)
                  handle.log(:info, "Successfully renamed #{options[:source_vm]} to #{options[:new_name]}.")
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
