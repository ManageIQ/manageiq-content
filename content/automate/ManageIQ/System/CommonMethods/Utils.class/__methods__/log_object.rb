#
# Description: Display Log messages for object attributes for root, current or desired object.
#

module ManageIQ
  module Automate
    module System
      module CommonMethods
        module Utils
          class LogObject
            # If you want to log the root MiqAeObject and use the global $evm
            #    ManageIQ::Automate::System::CommonMethods::Utils::LogObject.root
            #
            # If you want to log the root MiqAeObject and use a specific handle
            #    ManageIQ::Automate::System::CommonMethods::Utils::LogObject.root(handle)
            #
            def self.root(handle = $evm)
              log(handle.root, "root", handle)
            end

            # If you want to log the current MiqAeObject and use the global $evm
            #    ManageIQ::Automate::System::CommonMethods::Utils::LogObject.current
            #
            # If you want to log the current MiqAeObject and use a specific handle
            #    ManageIQ::Automate::System::CommonMethods::Utils::LogObject.current(handle)
            #
            def self.current(handle = $evm)
              log(handle.current, "current", handle)
            end

            # If you want to log a MiqAeObject and use the global $evm
            #    ManageIQ::Automate::System::CommonMethods::Utils::LogObject.log(vm)
            # If you want to log a specific MiqAeObject with custom header and footer message
            # This uses the global $evm
            #    ManageIQ::Automate::System::CommonMethods::Utils::LogObject.log(vm, "My Object")
            # If you want to log a specific MiqAeObject with custom header and an handle from an
            # instance method
            #    ManageIQ::Automate::System::CommonMethods::Utils::LogObject.log(vm, "My Object", @handle)

            def self.log(obj, object_string = 'Automation Object', handle = $evm)
              handle.log("info", "Listing #{object_string} Attributes - Begin")
              obj.attributes.sort.each { |k, v| handle.log("info", "   Attribute - #{k}: #{v}") }
              handle.log("info", "Listing #{object_string} Attributes - End")
            end
          end
        end
      end
    end
  end
end
