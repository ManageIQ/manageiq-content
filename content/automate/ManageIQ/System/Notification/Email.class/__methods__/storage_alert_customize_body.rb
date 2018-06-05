# This customizes and sets the body for MiqServer Alert

module ManageIQ
  module Automate
    module System
      module Notification
        module Email
          class StorageAlertCustomizeBody
            def initialize(handle = $evm)
              @handle = handle
            end

            def main
              @handle.log("info", "IBalls Detected Storage:<#{storage.inspect}>")
              build_body
            end

            private

            def build_body
              signature = @handle.object['signature']
              alert ||= @handle.root['miq_alert_description']
              subject = "#{alert} | Datastore: [#{storage}]"

              # Build Email Body
              body = "Attention, "
              body += "<br/>EVM Appliance: #{storage_href}"
              body += "<br/>EVM Region: #{@handle.root['miq_server'].region_number}"
              body += "<br/>Alert: #{alert}"
              body += "<br/><br/>"

              body += "<br/>Storage <b>#{storage}</b> Properties:"
              body += "<br/>Storage URL: <a href=#{storage_href}>"
              body += "#{storage_href}</a>"
              body += "<br/>Type: #{storage.store_type}"
              body += "<br/>Free Space: #{storage.free_space.to_i / (1024**3)} GB (#{storage.v_free_space_percent_of_total}%)"
              body += "<br/>Used Space: #{storage.v_used_space.to_i / (1024**3)} GB (#{storage.v_used_space_percent_of_total}%)"
              body += "<br/>Total Space: #{storage.total_space.to_i / (1024**3)} GB"
              body += "<br/><br/>"

              body += "<br/>Information for Registered VMs:"
              body += "<br/>Used + Uncommitted Space: #{storage.v_total_provisioned.to_i / (1024**3)} "
              body += "GB (#{storage.v_provisioned_percent_of_total}%)"
              body += "<br/><br/>"

              body += "<br/>Content:"
              body += "<br/>VM Provisioned Disk Files: #{storage.disk_size.to_i / (1024**3)} GB (#{storage.v_disk_percent_of_used}%)"
              body += "<br/>VM Snapshot Files: #{storage.snapshot_size.to_i / (1024**3)} GB (#{storage.v_snapshot_percent_of_used}%)"
              body += "<br/>VM Memory Files: #{storage.v_total_memory_size.to_i / (1024**3)} "
              body += "GB (#{storage.v_memory_percent_of_used}%)"
              body += "<br/><br/>"

              body += "<br/>Relationships:"
              body += "<br/>Number of Hosts attached: #{storage.v_total_hosts}"
              body += "<br/>Total Number of VMs: #{storage.v_total_vms}"
              body += "<br/><br/>"

              body += "<br/>Datastore Tags:"
              body += "<br/>#{storage.tags.inspect}"
              body += "<br/><br/>"

              body += "<br/>Regards,"
              body += "<br/>#{signature}"

              @handle.object['body'] = body
              @handle.object['subject'] = subject
            end

            def storage_href
              @storage_href ||= storage.show_url
            end

            def storage
              @storage ||= @handle.root["storage"].tap do |storage|
                raise "ERROR - storage not found" unless storage
              end
            end
          end
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  ManageIQ::Automate::System::Notification::Email::StorageAlertCustomizeBody.new.main
end
