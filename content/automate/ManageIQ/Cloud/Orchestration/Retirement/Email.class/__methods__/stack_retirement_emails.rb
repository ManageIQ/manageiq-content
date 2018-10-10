#
# Description: This method sends out retirement emails when the following events are raised:
#
# Events: stack_retire_warn, stack_retired, stack_entered_retirement
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
      module Orchestration
        module Retirement
          module StateMachines
            module Methods
              class StackRetirementEmails
                include ManageIQ::Automate::Cloud::Orchestration::Lifecycle::OrchestrationMixin

                def initialize(handle = $evm)
                  @handle = handle
                end

                def main
                  @handle.log("warn", "[DEPRECATION] This method will be deprecated. Please use similarly named method from System/Notification/Email class.")
                  stack = get_stack(@handle)

                  raise "Stack not specified" if stack.nil?

                  stack_name = stack['name']

                  event_type = @handle.object['event'] || @handle.root['event_type']

                  evm_owner_id = stack.attributes['evm_owner_id']
                  owner = nil
                  owner = @handle.vmdb('user', evm_owner_id) unless evm_owner_id.nil?

                  to = owner ? owner.email : @handle.object['to_email_address']

                  if event_type == "stack_retire_warn"

                    from = nil
                    from ||= @handle.object['from_email_address']

                    signature = nil
                    signature ||= @handle.object['signature']

                    subject = "Stack Retirement Warning for #{stack_name}"

                    body = "Hello, "
                    body += "<br><br>Your stack: [#{stack_name}] will be retired on [#{stack['retires_on']}]."
                    body += "<br><br>If you need to use this stack past this date please request an"
                    body += "<br><br>extension by contacting Support."
                    body += "<br><br> Thank you,"
                    body += "<br> #{signature}"
                  end

                  if event_type == "stack_entered_retirement"

                    from = nil
                    from ||= @handle.object['from_email_address']

                    signature = nil
                    signature ||= @handle.object['signature']

                    subject = "Stack #{stack_name} has entered retirement"

                    body = "Hello, "
                    body += "<br><br>Your stack named [#{stack_name}] has been retired."
                    body += "<br><br>You will have up to 3 days to un-retire this stack. Afterwhich time the stack will be deleted."
                    body += "<br><br> Thank you,"
                    body += "<br> #{signature}"
                  end

                  if event_type == "stack_retired"

                    from = nil
                    from ||= @handle.object['from_email_address']

                    signature = nil
                    signature ||= @handle.object['signature']

                    subject = "Stack Retirement Alert for #{stack_name}"

                    body = "Hello, "
                    body += "<br><br>Your stack named [#{stack_name}] has been retired."
                    body += "<br><br> Thank you,"
                    body += "<br> #{signature}"
                  end

                  @handle.log("info", "Sending email to <#{to}> from <#{from}> subject: <#{subject}>") if @debug
                  @handle.execute('send_email', to, from, subject, body)
                end
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Cloud::Orchestration::Retirement::StateMachines::Methods::StackRetirementEmails.new.main
