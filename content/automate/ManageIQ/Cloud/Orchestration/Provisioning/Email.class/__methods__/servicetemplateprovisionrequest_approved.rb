#
# Description: This method is used to email the provision requester that
# the Service provisioning request has been approved
#
# Events: request_approved
#
# Model Notes:
# 1. to_email_address - used to specify an email address in the case where the
#    requester does not have a valid email address. To specify more than one email
#    address separate email address with commas. (I.e. admin@example.com,user@example.com)
# 2. from_email_address - used to specify an email address in the event the
#    requester replies to the email
# 3. signature - used to stamp the email with a custom signature
#
module ManageIQ
  module Automate
    module Cloud
      module Orchestration
        module Provisioning
          module Email
            class ServiceTemplateProvisionRequestApproved
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                # Get miq_request from root
                miq_request = @handle.root['miq_request']
                raise 'miq_request is missing' if miq_request.nil?

                @handle.log("info",
                            "Detected Request:<#{miq_request.id}> with Approval State:<#{miq_request.approval_state}>")

                # appliance ||= 'evmserver.example.com'
                appliance = @handle.root['miq_server'].ipaddress

                # Email Requester
                email_requester(miq_request, appliance)
              end

              private

              def email_requester(miq_request, appliance)
                @handle.log('info', "Requester email logic starting")

                # Get requester object
                requester = miq_request.requester

                # Get requester email else set to nil
                requester_email = requester.email

                # Get Owner Email else set to nil
                owner_email = miq_request.options[:owner_email]
                @handle.log('info', "Requester email:<#{requester_email}> Owner Email:<#{owner_email}>")

                # Get to, from and signature parameters for email
                to, from, signature = email_params(requester_email)

                # Build subject
                subject = "Request ID #{miq_request.id} - Your Service provision request was Approved"

                # Build email body
                body = build_requester_email_body(miq_request, appliance, signature)

                # Send email
                @handle.log("info", "Sending email to <#{to}> from <#{from}> subject: <#{subject}>")
                @handle.execute(:send_email, to, from, subject, body)
              end

              def email_params(requester_email)
                # If requester_email is nil use to_email_address from model
                to = requester_email || @handle.object['to_email_address']

                # Get from_email_address from model unless specified below
                from = @handle.object['from_email_address']

                # Get signature from model unless specified below
                signature = @handle.object['signature']

                return to, from, signature
              end

              def build_requester_email_body(miq_request, appliance, signature)
                "Hello, <br>Your Service provision request was approved. If Service provisioning is successful"\
                " you will be notified via email when the Service is available.<br><br>Approvers notes: "\
                "#{miq_request.reason}<br><br>To view this Request go to: <a href='https://#{appliance}/"\
                "miq_request/show/#{miq_request.id}'>https://#{appliance}/miq_request/show/#{miq_request.id}</a>"\
                "<br><br> Thank you,<br> #{signature}"
              end

              def build_approver_email_body(miq_request, requester_email, appliance, signature)
                "Approver, <br>Service provision request received from #{requester_email} was approved.<br><br>"\
                "Approvers reason: #{miq_request.reason}br><br>To view this Request go to: <a href='https://"\
                "#{appliance}/miq_request/show/#{miq_request.id}'>https://#{appliance}/miq_request/show/"\
                "#{miq_request.id}</a><br><br> Thank you,<br> #{signature}"
              end

              def email_approver(miq_request, appliance)
                @handle.log('info', "Requester email logic starting")

                # Get requester object
                requester = miq_request.requester

                # Get requester email else set to nil
                requester_email = requester.email

                # Get to, from and signature parameters for email
                to, from, signature = email_params(requester_email)

                # Build subject
                subject = "Request ID #{miq_request.id} - Your Service provision request was Approved"

                # Build email body
                body = build_approver_email_body(miq_request, requester_email, appliance, signature)

                # Send email
                @handle.log("info", "Sending email to <#{to}> from <#{from}> subject: <#{subject}>")
                @handle.execute(:send_email, to, from, subject, body)
              end
            end
          end
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  ManageIQ::Automate::Cloud::Orchestration::Provisioning::
    Email::ServiceTemplateProvisionRequestApproved.new.main
end
