# This customizes and sets the body for MiqServer Alert

module ManageIQ
  module Automate
    module System
      module Notification
        module Email
          class MiqServerAlertCustomizeBody
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
              subject = "#{alert} | EVM Server: [#{miq_server.hostname}]"

              # Build Email Body
              body = "Attention,"
              body += "<br/>EVM Appliance: #{miq_server.ipaddress}"
              body += "<br/>EVM Region: #{@handle.root['miq_server'].region_number}"
              body += "<br/>Alert: #{alert}"
              body += "<br/><br/>"

              body += "<br/>EVM Server <b>#{miq_server.hostname}</b> Properties:"
              body += "<br>EVM Server URL: <a href=https://#{miq_server.ipaddress}>https://#{miq_server.ipaddress}</a>"
              body += "<br/>Hostname: #{miq_server.hostname}"
              body += "<br/>IP Address: #{miq_server.ipaddress}"
              body += "<br/>MAC Address: #{miq_server.mac_address}"
              body += "<br/>Last Heartbeat: #{miq_server.last_heartbeat}"
              body += "<br/>Master: #{miq_server.is_master}"
              body += "<br/>Status: #{miq_server.status}"
              body += "<br/>Started On: #{miq_server.started_on}"
              body += "<br/>Stopped On: #{miq_server.stopped_on}"
              body += "<br/>Version: #{miq_server.version}"
              body += "<br/>Zone: #{miq_server.zone}"
              body += "<br/>Id: #{miq_server.id}"
              body += "<br/><br/>"

              body += "<br/>Details:"
              body += "<br/>Memory Percentage: #{miq_server.percent_memory}"
              body += "<br/>Memory Usage: #{miq_server.memory_usage}"
              body += "<br/>Memory Size: #{miq_server.memory_size}"
              body += "<br/>CPU Percent: #{miq_server.percent_cpu}"
              body += "<br/>CPU Time: #{miq_server.cpu_time}"
              body += "<br/>Capabilities: #{miq_server.capabilities.inspect}"
              body += "<br/><br/>"

              body += "<br/>Regards,"
              body += "<br/>#{signature}"

              @handle.object['body'] = body
              @handle.object['subject'] = subject
            end

            def miq_server
              @miq_server ||= @handle.root["miq_server"].tap do |miq_server|
                raise "ERROR - miq_server not found" unless miq_server
              end
            end
          end
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  ManageIQ::Automate::System::Notification::Email::MiqServerAlertCustomizeBody.new.main
end
