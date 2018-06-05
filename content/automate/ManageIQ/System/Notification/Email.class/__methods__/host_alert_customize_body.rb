# This customizes and sets the body or Host Alert

module ManageIQ
  module Automate
    module System
      module Notification
        module Email
          class HostAlertCustomizeBody
            def initialize(handle = $evm)
              @handle = handle
            end

            def main
              @handle.log("info", "Detected Host:<#{host}>")
              build_body
            end

            private

            def build_body
              to = @handle.object['to']
              from = @handle.object['from']
              signature = @handle.object['signature']
              alert ||= @handle.root['miq_alert_description']
              subject = "#{alert} | Host: [#{host}]"

              # Build Email Body
              body = "Attention,"
              body += "<br/>EVM Appliance: #{host_href}"
              body += "<br/>EVM Region: #{@handle.root['miq_server'].region_number}"
              body += "<br/>Alert: #{alert}"
              body += "<br/><br/>"

              body += "<br/>Host <b>#{host}</b> Properties:"
              body += "<br/>Host URL: <a href=#{host_href}>#{host_href}</a>"
              body += "<br/>Hostname: #{host.hostname}"
              body += "<br/>IP Address(es): #{host.ipaddress}"
              body += "<br/>CPU Type: #{host.hardware.cpu_type}"
              body += "<br/>Cores per Socket: #{host.hardware.cpu_total_cores}"
              body += "<br/>vRAM: #{host.hardware.memory_mb.to_i / 1024} GB"
              body += "<br/>Operating System: #{host.vmm_product} #{host.vmm_version} Build #{host.vmm_buildnumber}"
              body += "<br/>SSH Permit Root: #{host.ssh_permit_root_login}"
              body += "<br/><br/>"

              body += "<br/>Power Maangement:"
              body += "<br/>Power State: #{host.power_state}"
              body += "<br/><br/>"

              body += "<br/>Relationships:"
              body += "<br/>Datacenter: #{host.v_owning_datacenter}"
              body += "<br/>Cluster: #{host.v_owning_cluster}"
              body += "<br/>Datastores: #{host.v_total_storages}"
              body += "<br/>VM(s): #{host.v_total_vms}"
              body += "<br/><br/>"

              body += "<br/>Host Tags:"
              body += "<br/>#{host.tags.inspect}"
              body += "<br/><br/>"

              body += "<br/>Regards,"
              body += "<br/>#{signature}"
              @handle.object['body'] = body
              @handle.object['subject'] = subject
              @handle.log("info", "Sending email To:<#{to}> From:<#{from}> subject:<#{subject}>")
            end

            def host_href
              @host_href ||= host.show_url
            end

            def host
              @host ||= @handle.root["host"].tap do |host|
                raise "ERROR - Host not found" unless host
              end
            end
          end
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  ManageIQ::Automate::System::Notification::Email::HostAlertCustomizeBody.new.main
end
