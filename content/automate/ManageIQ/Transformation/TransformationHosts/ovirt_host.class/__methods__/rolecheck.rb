module ManageIQ
  module Automate
    module Transformation
      module TransformationHost
        module OVirtHost
          class RoleCheck        
            def initialize(handle = $evm)
              @handle = handle
            end
            
            def main
              playbook = "/usr/share/doc/ovirt-ansible-v2v-conversion-host-1.0.0/examples/conversion_host_check.yml"
              extra_vars = { v2v_manageiq_conversion_host_check: true }

              result = Transformation::TransformationHosts::OVirtHost::Utils.ansible_playbook(@handle.root['host'], playbook, extra_vars)
              raise 'Conversion Host role is not enabled.' unless result[:rc].zero?
            end
          end
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  ManageIQ::Automate::Transformation::TransformationHost::OVirtHost::RoleCheck.new.main
end
