#
# Utility library for Red Hat Virtualization
#
require 'ovirtsdk4'

module ManageIQ
  module Automate
    module Transformation
      module Infrastructure
        module VM
          module RedHat
            class Utils
              
              def initialize(ems, handle = $evm)
                @debug      = true
                @handle     = handle
                @ems        = ems_to_service_model(ems)
                @connection = connection(@ems)
              end

              def get_export_domain
                storage_domains_service.list.select { |domain_service| 
                  domain_service.type == OvirtSDK4::StorageDomainType::EXPORT 
                }.first
              end
          
              def vm_import(vm_name, cluster, storage_domain)          
                target_domain = storage_domains_service.list(search: "name=#{storage_domain}").first
                raise "Can't find storage domain #{storage_domain}" if target_domain.blank?
                target_cluster = clusters_service.list(search: "name=#{cluster}").first
                raise "Can't find cluster #{cluster}" if target_cluster.blank?
                vm = vm_find_in_export_domain(vm_name)
                raise "Can't find VM #{vm_name} on export domain" if vm.blank?
                export_domain_vm_service(vm.id).import(
                  storage_domain: OvirtSDK4::StorageDomain.new(
                    id: target_domain.id
                  ),
                  cluster: OvirtSDK4::Cluster.new(
                    id: target_cluster.id
                  ),
                  vm: OvirtSDK4::Vm.new(
                    id: vm.id
                  )
                )
              end
          
              def vm_delete_from_export_domain(vm_name)
                vm = vm_find_in_export_domain(vm_name)
                raise "Can't find VM #{vm_name} on export domain" if vm.blank?            
                @handle.log(:info, "About to remove VM: #{vm_name}")
                export_domain_vm_service(vm.id).remove
              end
          
              def vm_find_by_name(vm_name)
                vms_service.list(search: "name=#{vm_name}").first
              end
          
              def vm_set_description(vm, description)
                vm_sdk = vm_find_by_name(vm.name)
                raise "Can't find VM #{vm_name} in RHV provider" if vm_sdk.blank?
                vm_service(vm_sdk.id).update(description: description)
                true
              end
            
              def vm_get_description(vm)
                vm_sdk = vm_find_by_name(vm.name)
                raise "Can't find VM #{vm_name} in RHV provider" if vm_sdk.blank?
                vm_sdk.description
              end
          
              def vm_enable_virtio_scsi(vm)
                vm_sdk = vm_find_by_name(vm.name)
                raise "Can't find VM #{vm_name}" if vm_sdk.blank?
                # Enable virtio_scsi in the VM
                vm_service(vm_sdk.id).update(virtio_scsi: {enabled: true})
                if vm_sdk.status == OvirtSDK4::VmStatus::DOWN
                  attachments_service = disk_attachments_service(vm_sdk.id)
                  attachments_service.list.each do | attachment |
                    attachments_service.attachment_service(attachment.id).update(
                      interface: OvirtSDK4::DiskInterface::VIRTIO_SCSI
                    )
                  end
                else
                  raise "VM must be down to enable virtio_scsi"
                end
              end
          
              def vm_set_nic_network(vm, nic, lan)
                vm_sdk = vm_find_by_name(vm.name)
                raise "Can't find VM #{vm_name} in RHV provider" if vm_sdk.blank?
                target_network = vnic_profiles_service.list.select { |vnic_profile| 
                  vnic_profile.network.id == lan.uid_ems 
                }.first
                raise "Can't find network #{lan.name} in RHV provider" if target_network.blank?
                nics_service = vm_nics_service(vm_sdk.id)
                target_nic = nics_service.list.select { |nic_sdk| 
                  nic_sdk.name == nic.device_name 
                }.first
                raise "Can't find nic #{nic.name} for VM #{vm_name}" if target_nic.blank?
                nics_service.nic_service(target_nic.id).update(
                  vnic_profile: target_network
                )
              end
          
              def vm_get_disk_interfaces(vm)
                disks = []
                vm_sdk = vm_find_by_name(vm.name)
                raise "Can't find VM #{vm.name} in RHV provider" if vm_sdk.blank?
                disk_attachments_service(vm_sdk.id).list.each do | attachment |
                  disks << attachment.interface
                end
                disks
              end
          
              private
          
              def ems_to_service_model(ems)
                raise "Invalid EMS" if ems.nil?
                # ems could be a numeric id or the ems object itself
                unless ems.is_a?(DRb::DRbObject) && /Manager/.match(ems.type.demodulize)
                  if /^\d{1,13}$/.match(ems.to_s)
                    ems = @handle.vmdb(:ems, ems)
                  end
                end
                ems
              end
          
              def vm_find_in_export_domain(vm_name)
                export_domain_vms_service.list.select { | export_vm | export_vm.name == vm_name }.first
              end
          
              def storage_domains_service
                @connection.system_service.storage_domains_service
              end
          
              def clusters_service
                @connection.system_service.clusters_service
              end
          
              def export_domain_vms_service
                export_domain = get_export_domain
                raise "No export domain found!" if export_domain.blank?
                storage_domains_service.storage_domain_service(export_domain.id).vms_service
              end
          
              def export_domain_vm_service(id)
                export_domain_vms_service.vm_service(id)
              end
          
              def vms_service
                @connection.system_service.vms_service
              end
          
              def networks_service
                @connection.system_service.networks_service
              end
          
             def vnic_profiles_service
                @connection.system_service.vnic_profiles_service
              end
          
              def vm_nics_service(id)
                vm_service(id).nics_service
              end
                
              def vm_service(id)
                vms_service.vm_service(id)
              end
          
              def disk_attachments_service(id)
                vm_service(id).disk_attachments_service
              end
          
              def connection(ems)
                connection = OvirtSDK4::Connection.new(
                  url: "https://#{ems.hostname}/ovirt-engine/api",
                  username: ems.authentication_userid,
                  password: ems.authentication_password,
                  insecure: true)
                connection if connection.test(true)
              end
    
            end
          end
        end
      end
    end
  end
end

