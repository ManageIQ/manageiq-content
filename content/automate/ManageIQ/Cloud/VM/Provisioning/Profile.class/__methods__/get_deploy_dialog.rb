#
# Description: Dynamically choose dialog based on Category:environment chosen in pre-dialog
#
module ManageIQ
  module Automate
    module Cloud
      module VM
        module Provisioning
          module Profile
            class GetDeployDialog
              def initialize(handle = $evm)
                @handle = handle
              end

              # Set run_env_dialog to true to dynamically choose dialog name based on environment tag
              def main(run_env_dialog = false)
                if run_env_dialog
                  # Get incoming environment tags from pre-dialog
                  dialog_input_vm_tags = @handle.root['dialog_input_vm_tags']

                  # Use a regular expression to grab the environment from the incoming tag category
                  # I.e. environment/dev for Category:environment Tag:dev
                  regex = /(.*)(\/)(\w*)/i

                  # If the regular express matches dynamically choose the next dialog
                  if regex =~ dialog_input_vm_tags
                    cat = Regexp.last_match[1]
                    tag = Regexp.last_match[3]
                    @handle.log("info", "Category: <#{cat}> Tag: <#{tag}>")
                    dialog_name = "miq_provision_dialogs-deploy-#{tag}"

                    ## Set dialog name in the root object to be picked up by dialogs
                    @handle.root['dialog_name'] = dialog_name
                    @handle.log("info", "Launching <#{dialog_name}>")
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

ManageIQ::Automate::Cloud::VM::Provisioning::Profile::GetDeployDialog.new.main
