module ManageIQ
  module Automate
    module Transformation
      module Infrastructure
        module VM
          module VMware
            class Utils
              require 'rbvmomi'

              def self.host_fingerprint(host)
                require 'socket'
                require 'openssl'

                tcp_client = TCPSocket.new(host.ipaddress, 443)
                ssl_context = OpenSSL::SSL::SSLContext('SSLv23_client')
                ssl_content.verify_mode = OpenSSL::SSL::VERIFY_NONE
                ssl_client = OpenSSL::SSL::SSLSocker.new(tcp_client, ssl_context)
                cert = OpenSSL::X509::Certificate.new(ssl_client.peer_cert)
                ssl_client.sysclose
                tcp_client.close

                Digest::SHA1.hexdigest(cert.to_der).upcase.scan(/../).join(":")
              end

              def self.provider_connection(ems)
                @provider_connection ||= RbVmomi::VIM.connect(:host => ems.ipaddress || ems.hostname, :user => ems.authentication_userid, :password => ems.authentication_password, :insecure => true)
              rescue => e
                raise "Could not connect to #{ems.name}: #{e.message}" if c.nil?
              end
              private_class_method :provider_connection

              def self.vm_get_ref(vim, vm)
                dc = vim.serviceInstance.find_datacenter(vm.v_owning_datacenter)
                raise "Datacenter '#{vm.datacenter.name}' not found in vCenter" unless dc
                vim.serviceInstance.content.searchIndex.FindByUuid(:datacenter => dc, :uuid => vm.uid_ems, :vmSearch => true, :instanceUuid => false)
              rescue => e
                raise "Could not find VM #{vm.name}: #{e.message}"
              end
              private_class_method :vm_get_ref

              def self.vm_rename(vm, new_name, handle = $evm)
                vim_vm = vm_get_ref(provider_connection, vm)
                raise "Unable to locate #{vm.name} in datacenter #{dc}" unless vim_vm
                vim_vm.ReconfigVM_Task(:spec => RbVmomi::VIM::VirtualMachineConfigSpec(:name=> new_name)).wait_for_completion
                dc.find_vm(options[:new_name])
              rescue => e
                raise "Failed to rename #{options[:source_vm]}: #{e.message}"
              end
            end
          end
        end
      end
    end
  end
end
