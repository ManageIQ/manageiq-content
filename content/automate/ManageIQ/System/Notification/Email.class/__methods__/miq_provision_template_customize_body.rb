# This customizes and sets the body

module ManageIQ
  module Automate
    module System
      module Notification
        module Email
          class MiqProvisionTemplateCustomizeBody
            def initialize(handle = $evm)
              @handle = handle
            end

            def main
              build_body
            end

            private

            def build_body
              to = @handle.object['to']
              signature = @handle.object['signature']
              # VM Provisioned Email Body
              body = "Hello,"
              body += "<br/><br/>Your request to publish from template was approved and completed on #{time}"
              body += "<br/><br/>Template <b>#{vm}</b> will be available in approximately 15 minutes</b>. "
              body += "<br/><br/>For Windows VM access is available via RDP and for Linux VM access is available via putty/ssh, etc."
              body += " Or you can use the Console Access feature found in the detail view of your VM. "
              if vm['retires_on'].respond_to?('strftime')
                body += "<br/><br/>This Template will automatically be retired on #{vm['retires_on'].strftime('%A, %B %d, %Y')},"
                body += " unless you request an extension. "
              end
              if vm.retirement_warn
                body += " You will receive a warning #{vm.retirement_warn} days before #{vm} "
                body += "set retirement date."
              end
              body += " As the designated owner you will receive expiration warnings at this email address: #{to}"
              body += "<br/><br/> If you have any issues with your new template please contact Support."
              body += "<br/><br/> Thank you,"
              body += "<br/> #{signature}"
              @handle.object['body'] = body
            end

            def provision
              @provision ||= @handle.root["miq_provision"].tap do |provision|
                raise "ERROR - miq_provision object not passed in" unless provision
              end
            end

            def vm_href
              @vm_href ||= vm.show_url
            end

            def time
              @time ||= Time.zone.now.strftime('%A, %B %d, %Y at %I:%M%p')
            end

            def vm
              @vm ||= provision.vm.tap do |vm|
                raise "ERROR - VM not found" unless vm
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::System::Notification::Email::MiqProvisionTemplateCustomizeBody.new.main
