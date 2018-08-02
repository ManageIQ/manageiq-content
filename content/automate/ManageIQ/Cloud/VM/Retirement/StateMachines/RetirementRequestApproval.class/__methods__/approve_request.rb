#
# Description: This method is executed when the provisioning request is auto-approved
#
module ManageIQ
  module Automate
    module Cloud
      module VM
        module Retirement
          module StateMachines
            module RetirementRequestApproval
              class ApproveRequest
                def initialize(handle = $evm)
                  @handle = handle
                end

                def main
                  # Auto-Approve request
                  @handle.log('info', 'Checking for auto_approval')
                  approval_type = @handle.object['approval_type'].try(:downcase)
                  if approval_type == 'auto'
                    @handle.log('info', 'AUTO-APPROVING')
                    @handle.root['miq_request'].approve('admin', 'Auto-Approved')
                  else
                    @handle.log('info', 'Not Auto-Approved')
                    raise 'Not Auto-Approved'
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Cloud::VM::Retirement::StateMachines::RetirementRequestApproval::ApproveRequest.new.main
