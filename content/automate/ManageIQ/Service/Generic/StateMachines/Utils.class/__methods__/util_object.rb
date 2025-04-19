#
# Description: Service utils methods
#
module ManageIQ
  module Automate
    module Service
      module Generic
        module StateMachines
          module Utils
            class UtilObject
              REQUEST_TO_SERVICE_ACTION = {
                "clone_to_service"    => "Provision",
                "service_reconfigure" => "Reconfigure",
                "service_retire"      => "Retirement"
              }.freeze

              REQUEST_TO_SERVICE_TASK = {
                "clone_to_service"    => "service_template_provision_task",
                "service_reconfigure" => "service_reconfigure_task",
                "service_retire"      => "service_retire_task"
              }.freeze

              def self.dump_root(handle = $evm)
                handle.log(:info, "Root:<$evm.root> Attributes - Begin")
                handle.root.attributes.sort.each { |k, v| handle.log(:info, "  Attribute - #{k}: #{v}") }
                handle.log(:info, "Root:<$evm.root> Attributes - End")
                handle.log(:info, "")
              end

              def self.service_task(handle = $evm)
                request = handle.root["request"]
                handle.root[REQUEST_TO_SERVICE_TASK[request]] unless request.nil?
              end

              def self.update_task(message, status = nil, handle = $evm)
                task = service_task(handle)
                unless task.nil?
                  task.miq_request.user_message = message
                  task.message = status unless status.nil?
                end
              end

              def self.service(handle = $evm)
                service = handle.root["service"] || service_task(handle)&.source
                service.tap do |s|
                  ManageIQ::Automate::System::CommonMethods::Utils::LogObject.log_and_raise("Service not found", handle) if s.nil?
                end
              end

              def self.service_action(handle = $evm)
                service_action = handle.root["service_action"] || REQUEST_TO_SERVICE_ACTION[handle.root["request"]]
                service_action.tap do |action|
                  unless %w[Provision Retirement Reconfigure].include?(action)
                    ManageIQ::Automate::System::CommonMethods::Utils::LogObject.log_and_raise("Invalid service_action", handle)
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
