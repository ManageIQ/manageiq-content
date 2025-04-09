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
              def self.dump_root(handle = $evm)
                handle.log(:info, "Root:<$evm.root> Attributes - Begin")
                handle.root.attributes.sort.each { |k, v| handle.log(:info, "  Attribute - #{k}: #{v}") }
                handle.log(:info, "Root:<$evm.root> Attributes - End")
                handle.log(:info, "")
              end

              def self.update_task(message, status = nil, handle = $evm)
                task_name = case handle.root["request"]
                            when "service_reconfigure"
                              "service_reconfigure_task"
                            when "service_retire"
                              "service_retire_task"
                            else
                              "service_template_provision_task"
                            end
                handle.root[task_name].try do |task|
                  task.miq_request.user_message = message
                  task.message = status unless status.nil?
                end
              end

              def self.service(handle = $evm)
                if handle.root["request"] == "service_reconfigure"
                  task = handle.root["service_reconfigure_task"]
                  service = task.source unless task.nil?
                else
                  service = handle.root["service"]
                end

                if service.nil?
                  ManageIQ::Automate::System::CommonMethods::Utils::LogObject.log_and_raise("ERROR - Service not found", handle)
                end

                service
              end

              def self.service_action(handle = $evm)
                return "Reconfigure" if handle.root["request"] == "service_reconfigure"

                handle.root["service_action"].tap do |action|
                  unless %w[Provision Retirement Reconfigure].include?(action)
                    ManageIQ::Automate::System::CommonMethods::Utils::LogObject.log_and_raise("ERROR - Invalid service action: #{action}", handle)
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
