# This customizes and sets the body for Emscluster Alert

module ManageIQ
  module Automate
    module System
      module Notification
        module Email
          class EmsClusterAlertCustomizeBody
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
              subject = "#{alert} | Cluster: [#{ems_cluster.name}]"

              # Build Email Body
              body = "Attention,"
              body += "<br/>EVM Appliance: #{ems_cluster_href}"
              body += "<br/>EVM Region: #{@handle.root['miq_server'].region_number}"
              body += "<br/>Alert: #{alert}"
              body += "<br/><br/>"

              body += "<br/>Cluster <b>#{ems_cluster.name}</b> Properties:"
              body += "<br/>Cluster URL: <a href=#{ems_cluster_href}>"
              body += "#{ems_cluster_href}</a>"
              body += "<br/>Total Host CPU Resources: #{ems_cluster.aggregate_cpu_speed}"
              body += "<br/>Total Host Memory: #{ems_cluster.aggregate_memory}"
              body += "<br/>Total Host CPUs: #{ems_cluster.aggregate_physical_cpus}"
              body += "<br/>Total Host CPU Cores: #{ems_cluster.aggregate_cpu_total_cores}"
              body += "<br/>Total Configured VM Memory: #{ems_cluster.aggregate_vm_memory}"
              body += "<br/>Total Configured VM CPUs: #{ems_cluster.aggregate_vm_cpus}"
              body += "<br/><br/>"

              body += "<br/>Configuration:"
              body += "<br/>HA Enabled: #{ems_cluster.ha_enabled}"
              body += "<br/>HA Admit Control: #{ems_cluster.ha_admit_control}"
              body += "<br/>DRS Enabled: #{ems_cluster.drs_enabled}"
              body += "<br/>DRS Automation Level: #{ems_cluster.drs_automation_level}"
              body += "<br/>DRS Migration Threshold: #{ems_cluster.drs_migration_threshold}"
              body += "<br/><br/>"

              body += "<br/>Relationships:"
              body += "<br/>Datacenter: #{ems_cluster.v_parent_datacenter}"
              body += "<br/>Hosts: #{ems_cluster.total_hosts}"
              body += "<br/>VM(s): #{ems_cluster.total_vms}"
              body += "<br/><br/>"

              body += "<br/>Cluster Tags:"
              body += "<br/>#{ems_cluster.tags.inspect}"
              body += "<br/><br/>"

              body += "<br/>Regards,"
              body += "<br/>#{signature}"

              @handle.object['body'] = body
              @handle.object['subject'] = subject
            end

            def ems_cluster_href
              @ems_cluster_href ||= ems_cluster.show_url
            end

            def ems_cluster
              @ems_cluster ||= @handle.root["ems_cluster"].tap do |ems_cluster|
                raise "ERROR - ems_cluster not found" unless ems_cluster
              end
            end
          end
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  ManageIQ::Automate::System::Notification::Email::EmsClusterAlertCustomizeBody.new.main
end
