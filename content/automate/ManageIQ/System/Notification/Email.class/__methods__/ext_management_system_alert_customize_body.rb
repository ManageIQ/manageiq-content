# This customizes and sets the body for ExtManagementSystem Alert

module ManageIQ
  module Automate
    module System
      module Notification
        module Email
          class ExtManagementSystemAlertCustomizeBody
            def initialize(handle = $evm)
              @handle = handle
            end

            def main
              build_body
            end

            private

            def build_body
              signature = @handle.object['signature']
              alert ||= @handle.root['miq_alert_description']
              subject = "#{alert} | vCenter: [#{ext_management_system}]"

              # Build Email Body
              body = "Attention,"
              body += "<br/>EVM Appliance: #{@handle.root['miq_server'].hostname}"
              body += "<br/>EVM Region: #{@handle.root['miq_server'].region_number}"
              body += "<br/>Alert: #{alert}"
              body += "<br/><br/>"

              body += "<br/>vCenter <b>#{ext_management_system.name}</b> Properties:"
              body += "<br/>Hostname: #{ext_management_system.hostname}"
              body += "<br/>IP Address(es): #{ext_management_system.ipaddress}"
              body += "<br/>Host Information:"
              body += "<br/>Aggregate Host CPU Speed: #{ext_management_system.aggregate_cpu_speed.to_i / 1000} Ghz"
              body += "<br/>Aggregate Host CPU Cores: #{ext_management_system.aggregate_cpu_total_cores}"
              body += "<br/>Aggregate Host Memory: #{ext_management_system.aggregate_memory}"
              body += "<br/>SSH Permit Root: #{ext_management_system.aggregate_vm_cpus}"
              body += "<br/><br/>"

              body += "<br/>VM Information:"
              body += "<br/>Aggregate VM Memory: #{ext_management_system.aggregate_vm_memory} bytes"
              body += "<br/>Aggregate VM CPUs: #{ext_management_system.aggregate_vm_cpus} bytes"
              body += "<br/><br/>"

              body += "<br/>Relationships:"
              body += "<br/>Hosts: #{ext_management_system.total_hosts}"
              body += "<br/>Datastores: #{ext_management_system.total_storages}"
              body += "<br/>VM(s): #{ext_management_system.total_vms}"
              body += "<br/><br/>"

              body += "<br/>Host Tags:"
              body += "<br/>#{ext_management_system.tags.inspect}"
              body += "<br/><br/>"

              body += "<br/>Regards,"
              body += "<br/>#{signature}"

              @handle.object['body'] = body
              @handle.object['subject'] = subject
            end

            def ext_management_system_href
              @ext_management_system_href ||= ext_management_system.show_url
            end

            def ext_management_system
              @ext_management_system ||= @handle.root["ext_management_system"].tap do |ext_management_system|
                raise "ERROR - ext_management_system not found" unless ext_management_system
              end
            end
          end
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  ManageIQ::Automate::System::Notification::Email::ExtManagementSystemAlertCustomizeBody.new.main
end
