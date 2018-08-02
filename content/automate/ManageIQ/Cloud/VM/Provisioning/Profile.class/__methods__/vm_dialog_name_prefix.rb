#
# Description: This is the default method to determine the dialog prefix name to use
#
module ManageIQ
  module Automate
    module Cloud
      module VM
        module Provisioning
          module Profile
            class VmDialogNamePrefix
              def initialize(handle = $evm)
                @handle = handle
              end

              # Set run_env_dialog to true to dynamically choose dialog name based on environment tag
              def main
                platform = @handle.root['platform']
                @handle.log("info", "Detected Platform:<#{platform}>")

                if platform.nil?
                  source_id = @handle.root['dialog_input_src_vm_id']
                  source    = @handle.vmdb('vm_or_template', source_id) unless source_id.nil?
                  platform  = source ? source.model_suffix.downcase : "vmware"
                end

                dialog_name_prefix = "miq_provision_#{platform}_dialogs"
                @handle.object['dialog_name_prefix'] = dialog_name_prefix
                @handle.log("info", "Platform:<#{platform}> dialog_name_prefix:<#{dialog_name_prefix}>")
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Cloud::VM::Provisioning::Profile::VmDialogNamePrefix.new.main
