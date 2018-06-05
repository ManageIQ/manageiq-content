# This customizes and sets the body for Emscluster Alert

module ManageIQ
  module Automate
    module System
      module Notification
        module Email
          class VmAlertCustomizeBody
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
              subject = "#{alert} | VM: [#{vm}]"

              # Build Email Body
              body = "Attention,"
              body += "<br/>EVM Appliance: #{vm_href}"
              body += "<br/>EVM Region: #{@handle.root['miq_server'].region_number}"
              body += "<br/>Alert: #{alert}"
              body += "<br/><br/>"

              body += "<br/>VM <b>#{vm}</b> Properties:"
              body += "<br/>VM URL: <a href=#{vm_href}>#{vm_href}</a>"
              body += "<br/>Hostname: #{vm.hostnames.inspect}"
              body += "<br/>IP Address(es): #{vm.ipaddresses.inspect}"
              body += "<br/>vCPU: #{vm.cpu_total_cores}"
              body += "<br/>vRAM: #{vm.mem_cpu.to_i} MB"
              body += "<br/>Tools Status: #{vm.tools_status}"
              body += "<br/>Operating System: #{vm.operating_system['product_name']}"
              body += "<br/>Disk Alignment: #{vm.disks_aligned}"
              body += "<br/><br/>"

              body += "<br/>Power Maangement:"
              body += "<br/>Power State: #{vm.power_state}"
              body += "<br/>Last Boot: #{vm.boot_time}"
              body += "<br/><br/>"

              body += "<br/>Snapshot Information:"
              body += "<br/>Total Snapshots: #{vm.v_total_snapshots}"
              body += "<br/>Total Snapshots: #{vm.v_total_snapshots}"
              body += "<br/><br/>"

              body += "<br/>Relationships:"
              body += "<br/>Datacenter: #{vm.v_owning_datacenter}"
              body += "<br/>Cluster: #{vm.ems_cluster_name}"
              body += "<br/>Host: #{vm.host_name}"
              body += "<br/>Datastore Path: #{vm.v_datastore_path}"
              body += "<br/>Resource Pool: #{vm.v_owning_resource_pool}"
              body += "<br/><br/>"

              body += "<br/>VM Tags:"
              body += "<br/>#{vm.tags.inspect}"
              body += "<br/><br/>"

              body += "<br/>Regards,"
              body += "<br/>#{signature}"

              @handle.object['body'] = body
              @handle.object['subject'] = subject
            end

            def vm_href
              @vm_href ||= vm.show_url
            end

            def vm
              @vm ||= @handle.root["vm"].tap do |vm|
                raise "ERROR - vm not found" unless vm
              end
            end
          end
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  ManageIQ::Automate::System::Notification::Email::VmAlertCustomizeBody.new.main
end
