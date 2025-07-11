#
# Description: This method prepares arguments and parameters for execution
module ManageIQ
  module Automate
    module Service
      module Generic
        module StateMachines
          module GenericLifecycle
            class PreProcess
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                @handle.log(:info, "Starting preprocess")

                begin
                  dump_root
                  options = update_options
                  # user can insert options to override options from dialog
                  # or user changes the input params values, eg. ServiceTerraformTemplate
                  service.preprocess(service_action, options)
                  @handle.root['ae_result'] = 'ok'
                  @handle.log(:info, "Ending preprocess")
                rescue => err
                  @handle.root['ae_result'] = 'error'
                  @handle.root['ae_reason'] = err.message
                  @handle.log(:error, "Error in preprocess: #{err.message}")
                  update_task(err.message)
                end
              end

              private

              def dump_root
                ManageIQ::Automate::Service::Generic::StateMachines::Utils::UtilObject.dump_root(@handle)
              end

              def update_task(message, status = nil)
                ManageIQ::Automate::Service::Generic::StateMachines::Utils::UtilObject.update_task(message, status, @handle)
              end

              def service
                ManageIQ::Automate::Service::Generic::StateMachines::Utils::UtilObject.service(@handle)
              end

              def service_action
                ManageIQ::Automate::Service::Generic::StateMachines::Utils::UtilObject.service_action(@handle)
              end

              # User changes to the input params values, eg. ServiceTerraformTemplate
              def reconfiguration_options
                task = @handle.root["service_reconfigure_task"]
                {:dialog => task.options[:dialog] || {}}
              end

              def update_options
                if service_action == 'Reconfigure'
                  reconfiguration_options
                else
                  # user can insert options to override options from dialog
                  {}
                end
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Service::Generic::StateMachines::GenericLifecycle::PreProcess.new.main
