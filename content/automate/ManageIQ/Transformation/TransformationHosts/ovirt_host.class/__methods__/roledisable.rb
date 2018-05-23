module ManageIQ
  module Automate
    module Transformation
      module TransformationHost
        module OVirtHost
          class RoleDisable
            def initialize(handle = $evm)
              @handle = handle
            end
            
            def main
              host = @handle.root['host']
              playbook = "/usr/share/doc/ovirt-ansible-v2v-conversion-host-1.0.0/examples/conversion_host_disable.yml"
              extra_vars = {}

              result = Transformation::TransformationHosts::OVirtHost::Utils.ansible_playbook(host, playbook, extra_vars)
              @handle.log(:error, "Failed to disable Conversion Host role for '#{host.name}'.") unless result[:rc].zero?
            end
          end
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  ManageIQ::Automate::Transformation::TransformationHost::OVirtHost::RoleDisable.new.main
end
