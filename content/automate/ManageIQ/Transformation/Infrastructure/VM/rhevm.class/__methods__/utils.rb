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

              def vm_find_by_name(vm_name)
                vms_service.list(:search => "name=#{vm_name}").first
              end

              def vm_set_description(vm, description)
                vm_sdk = vm_find_by_name(vm.name)
                raise "Can't find VM #{vm.name} in RHV provider" if vm_sdk.blank?
                vm_service(vm_sdk.id).update(:description => description)
                true
              end

              private

              def ems_to_service_model(ems)
                raise "Invalid EMS" if ems.nil?
                # ems could be a numeric id or the ems object itself
                unless ems.kind_of?(DRb::DRbObject) && /Manager/.match(ems.type.demodulize)
                  if ems.to_s =~ /^\d{1,13}$/
                    ems = @handle.vmdb(:ems, ems)
                  end
                end
                ems
              end

              def vms_service
                @connection.system_service.vms_service
              end

              def vm_service(id)
                vms_service.vm_service(id)
              end

              def connection(ems)
                connection = OvirtSDK4::Connection.new(
                  :url      => "https://#{ems.hostname}/ovirt-engine/api",
                  :username => ems.authentication_userid,
                  :password => ems.authentication_password,
                  :insecure => true
                )
                connection if connection.test(true)
              end
            end
          end
        end
      end
    end
  end
end
