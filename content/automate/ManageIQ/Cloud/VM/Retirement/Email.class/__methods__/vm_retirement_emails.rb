#
# Description: This method sends out retirement emails when the following events are raised:
#
# Events: vm_retire_warn, vm_retired, vm_entered_retirement
#
# Model Notes:
# 1. to_email_address - used to specify an email address in the case where the
#    vm's owner does not have an  email address. To specify more than one email
#    address separate email address with commas. (I.e. admin@example.com,user@example.com)
# 2. from_email_address - used to specify an email address in the event the
#    requester replies to the email
# 3. signature - used to stamp the email with a custom signature
#
module ManageIQ
  module Automate
    module Cloud
      module VM
        module Retirement
          module Email
            class VmRetirementEmails
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                @vm           = vm_from_evm
                evm_owner_id  = @vm.attributes['evm_owner_id']
                owner         = evm_owner_id.nil? ? nil : @handle.vmdb('user', evm_owner_id)
                to            = owner ? owner.email : @handle.object['to_email_address']
                from          = @handle.object['from_email_address']
                subject, body = subject_and_body

                @handle.log("info", "Sending email to <#{to}> from <#{from}> subject: <#{subject}>") if @debug
                @handle.execute('send_email', to, from, subject, body)
              end

              private

              def vm_from_evm
                vm_id = @handle.object['vm'].try(:id) || @handle.object['vm_id'] ||
                        @handle.root['vm'].try(:id)   || @handle.root['vm_id']   ||
                        @handle.root['miq_provision_request'].try(:vm).try(:id)  ||
                        @handle.root['miq_provision'].try(:vm).try(:id)

                vm_id ? @handle.vmdb('vm', vm_id) : raise('User not specified')
              end

              def subject_and_body
                case @handle.object['event'] || @handle.root['event_type']
                when "vm_retire_warn"
                  subject, body = vm_retire_warn
                when "vm_retire_extend"
                  subject, body = vm_retire_extend
                when "vm_entered_retirement"
                  subject, body = vm_entered_retirement
                when "vm_retired"
                  subject, body = vm_retired
                end

                [subject, body]
              end

              def vm_retire_warn
                vm_name = @vm['name']
                subject = "VM Retirement Warning for #{vm_name}"

                body = "Hello, "
                body += "<br><br>Your virtual machine: [#{vm_name}] will be retired on [#{@vm['retires_on']}]."
                body += "<br><br>If you need to use this virtual machine past this date please request an"
                body += "<br><br>extension by contacting Support."
                body += "<br><br> Thank you,"
                body += "<br> #{@handle.object['signature']}"

                [subject, body]
              end

              def vm_retire_extend
                vm_name = @vm['name']
                subject = "VM Retirement Extended for #{vm_name}"

                body = "Hello, "
                body += "<br><br>Your virtual machine: [#{vm_name}] will now be retired on [#{@vm['retires_on']}]."
                body += "<br><br>If you need to use this virtual machine past this date please request an"
                body += "<br><br>extension by contacting Support."
                body += "<br><br> Thank you,"
                body += "<br> #{@handle.object['signature']}"

                [subject, body]
              end

              def vm_entered_retirement
                vm_name = @vm['name']
                subject = "VM #{vm_name} has entered retirement"

                body = "Hello, "
                body += "<br><br>Your virtual machine named [#{vm_name}] has been retired."
                body += "<br><br>You will have up to 3 days to un-retire this VM. Afterwhich time the VM will be deleted."
                body += "<br><br> Thank you,"
                body += "<br> #{@handle.object['signature']}"

                [subject, body]
              end

              def vm_retired
                vm_name = @vm['name']
                subject = "VM Retirement Alert for #{vm_name}"

                body = "Hello, "
                body += "<br><br>Your virtual machine named [#{vm_name}] has been retired."
                body += "<br><br> Thank you,"
                body += "<br> #{@handle.object['signature']}"

                [subject, body]
              end
            end
          end
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  ManageIQ::Automate::Cloud::VM::Retirement::Email::VmRetirementEmails.new.main
end
