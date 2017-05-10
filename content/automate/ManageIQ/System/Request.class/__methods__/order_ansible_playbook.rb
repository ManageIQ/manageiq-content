# Description: Launch an ansible playbook service
# Required Parameters in the root object
#   service_template_name
# Optional Parameters in the root object
# hosts   localhost|vm|ip1,ip2,ip3
#   vm    If the hosts is vm, at runtime will use the ip address of the vm in the hosts field

module ManageIQ
  module Automate
    module System
      module Request
        class OrderAnsiblePlaybook
          ANSIBLE_DIALOG_VAR_REGEX = Regexp.new(/dialog_param_(.*)/)
          def initialize(handle = $evm)
            @handle = handle
          end

          def main
            request = @handle.create_service_provision_request(service_template, extra_vars.merge(:hosts => hosts))
            @handle.log(:info, "Submitted provision request #{request.id} for service template #{service_template_name}")
          end

          private

          def extra_vars
            key_list = @handle.root.attributes.keys.select { |k| k.start_with?('dialog_param') }
            key_list.each_with_object({}) do |key, hash|
              match_data = ANSIBLE_DIALOG_VAR_REGEX.match(key)
              hash["param_#{match_data[1]}"] = @handle.root[key] if match_data
            end
          end

          def hosts
            if @handle.root['hosts'] == 'vm'
              vm_ip
            else
              @handle.root['hosts'] || @handle.root['dialog_hosts']
            end
          end

          def vm_ip
            raise "VM object not passed in" unless @handle.root['vm']

            @handle.root['vm'].ipaddresses.try(:first).tap do |ip|
              if ip.nil?
                @handle.log(:error, "IP address not specified for vm: #{@handle.root['vm'].name}")
                raise "IP address not specified for vm: #{@handle.root['vm'].name}"
              end
            end
          end

          def service_template
            @service_template ||= @handle.vmdb('ServiceTemplate').where(:name => service_template_name).first.tap do |st|
              if st.nil?
                @handle.log(:error, "Service Template #{@handle.root['service_template_name']} not found")
                raise "Service Template #{@handle.root['service_template_name']} not found"
              end
            end
          end

          def service_template_name
            if @handle.root['service_template_name'].nil?
              @handle.log(:error, "service_template_name is a required parameter")
              raise "service_template_name is a required parameter"
            end
            @handle.root['service_template_name']
          end
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  ManageIQ::Automate::System::Request::OrderAnsiblePlaybook.new.main
end
