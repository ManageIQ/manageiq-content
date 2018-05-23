module ManageIQ
  module Automate
    module Transformation
      module TransformationHost
        module OVirtHost
          class RoleEnable
            def initialize(handle = $evm)
              @handle = handle
            end
            
            def main
              host = @handle.root['host']
              playbook = "/usr/share/doc/ovirt-ansible-v2v-conversion-host-1.0.0/examples/conversion_host_enable.yml"
              extra_vars = {}
              extra_vars[:v2v_vddk_package_name] = "VMware-vix-disklib-stable.tar.gz"
              extra_vars[:v2v_vddk_package_url] = "http://#{host.ext_management_system.hostname}/vddk/#{extra_vars[:v2v_vddk_package_name]}"
              # TODO: Remove the RPM repositories as they are provided by oVirt/RHV
              extra_vars[:v2v_repo_rpms_name] = "v2v-nbdkit-rpms"
              extra_vars[:v2v_repo_rpms_url] = "http://#{host.ext_management_system.hostname}/rpms/#{extra_vars[:v2v_repo_rpms_name]}"
              extra_vars[:v2v_repo_srpms_name] = "v2v-nbdkit-src-rpms"
              extra_vars[:v2v_repo_srpms_url] = "http://#{host.ext_management_system.hostname}/rpms/#{extra_vars[:v2v_repo_srpms_name]}"

              result = Transformation::TransformationHosts::OVirtHost::Utils.ansible_playbook(host, playbook, extra_vars)
              @handle.log(:error, "Failed to enable Conversion Host role for '#{host.name}'.") unless result[:rc].zero?
            end
          end
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  ManageIQ::Automate::Transformation::TransformationHost::OVirtHost::RoleEnable.new.main
end
