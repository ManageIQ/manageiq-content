#
# Description: This method prepares arguments and parameters for execution
module ManageIQ
  module Automate
    module Service
      module Generic
        module StateMachines
          module GenericLifecycle
            class ReconfigurePreProcess
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                @handle.log(:info, "Starting Reconfigure Preprocess")

                begin
                  dump_root
                  options = update_options
                  # user can insert options to override options from dialog
                  service.preprocess(service_action, options)
                  @handle.root['ae_result'] = 'ok'
                  @handle.log(:info, "Ending preprocess")
                rescue => err
                  @handle.root['ae_result'] = 'error'
                  @handle.root['ae_reason'] = err.message
                  @handle.log(:error, "Error in Reconfigure Preprocess: #{err.message}")
                  update_task(err.message)
                end
              end

              private

              def dump_root
                @handle.log(:info, "Root:<$evm.root> Attributes - Begin")
                @handle.root.attributes.sort.each { |k, v| @handle.log(:info, "  Attribute - #{k}: #{v}") }
                @handle.log(:info, "Root:<$evm.root> Attributes - End")
                @handle.log(:info, "")
              end

              def update_task(message)
                if @handle.root["request"] == "service_reconfigure"
                  @handle.root['service_reconfigure_task'].try { |task| task.miq_request.user_message = message }
                else
                  @handle.root['service_template_provision_task'].try { |task| task.miq_request.user_message = message }
                end
              end

              def service
                service = @handle.root["service"]
                if service.nil?
                  task = @handle.root["service_reconfigure_task"]
                  service = task.source unless task.nil?
                end
                if service.nil?
                  ManageIQ::Automate::System::CommonMethods::Utils::LogObject.log_and_raise("ERROR - Service not found", @handle)
                end
                service
              end

              def service_action
                action = @handle.root["service_action"]
                if action.nil? && @handle.root["request"] == "service_reconfigure"
                  action = "Reconfigure"
                end
                unless %w[Provision Retirement Reconfigure].include?(action)
                  ManageIQ::Automate::System::CommonMethods::Utils::LogObject.log_and_raise("ERROR - Invalid service action: #{action}", @handle)
                end
                action
              end

              def reconfiguration_options
                task = @handle.root["service_reconfigure_task"]
                {:dialog => task.options[:dialog] || {}}
              end

              def update_options
                if service_action == 'Reconfigure'
                  reconfiguration_options
                else
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

ManageIQ::Automate::Service::Generic::StateMachines::GenericLifecycle::ReconfigurePreProcess.new.main
