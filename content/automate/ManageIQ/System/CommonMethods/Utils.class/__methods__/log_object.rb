#
# Description: Display Log messages for object attributes for root, current or desired object.
# Added InspectMe functionality
# Added log_and_notify

module ManageIQ
  module Automate
    module System
      module CommonMethods
        module Utils
          class LogObject
            NOTIFY_LEVEL_TO_LOG_LEVEL = {
              'info'    => 'info',
              'warning' => 'warn',
              'error'   => 'error',
              'success' => 'info'
            }.freeze
            # If you want to log a message and exit without specifying a handle using the global $evm
            #    ManageIQ::Automate::System::CommonMethods::Utils::LogObject.log_and_exit(msg, code)
            #
            # If you want to log a message and exit using a specific handle
            #    ManageIQ::Automate::System::CommonMethods::Utils::LogObject.log_and_exit(msg, code, handle)
            #
            def self.log_and_exit(msg, exit_code, handle = $evm)
              handle.log('info', "Script ending #{msg} code : #{exit_code}")
              exit(exit_code)
            end

            # If you want to create a notification and log a message without specifying a handle using the global $evm
            #    ManageIQ::Automate::System::CommonMethods::Utils::LogObject.log_and_notify(notify_level, msg, subject)
            #
            # If you want to create a notification and log a message using a specific handle
            #    ManageIQ::Automate::System::CommonMethods::Utils::LogObject.log_and_notify(notify_level, msg, subject, handle)
            #
            # Valid types are : info, warning, error and success
            def self.log_and_notify(notify_level, message, subject, handle = $evm)
              raise "Invalid notify level #{notify_level}" unless NOTIFY_LEVEL_TO_LOG_LEVEL.keys.include?(notify_level.downcase.to_s)
              handle.create_notification(:level => notify_level.downcase, :message => message, :subject => subject)
              handle.log(NOTIFY_LEVEL_TO_LOG_LEVEL[notify_level.downcase.to_s], message)
            end

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

            def self.log(obj, log_prefix = 'Automation Object', handle = $evm)
              handle.log("info", "Listing #{log_prefix} Attributes - Begin")
              obj.attributes.sort.each { |k, v| handle.log("info", "   Attribute - #{k}: #{v}") }
              handle.log("info", "Listing #{log_prefix} Attributes - End")
            end

            def self.log_and_raise(message, handle = $evm)
              handle.log("error", message)
              raise message.to_s
            end

            def self.ar_object?(obj)
              obj.respond_to?(:object_class)
            end

            def self.log_ar_objects(log_prefix = 'VMDB Object', handle = $evm)
              handle.log("info", "#{log_prefix} log_ar_objects Begins")
              handle.root.attributes.sort.each do |k, v|
                log_ar_object(k, v, log_prefix, handle) if ar_object?(v)
              end
            end

            def self.log_ar_object(key, object, log_prefix, handle = $evm)
              handle.log("info", "key:<#{key}>  object:<#{object}>")
              attributes(object, log_prefix, handle)
              associations(object, log_prefix, handle)
              tags(object, log_prefix, handle)
            end

            def self.attributes(obj, log_prefix, handle = $evm)
              handle.log("info", " #{log_prefix} Begin Attributes [object.attributes]")
              obj.attributes.sort.each do |k, v|
                handle.log("info", "  Attribute:  #{k} = #{v.inspect}")
              end
              handle.log("info", " #{log_prefix} End Attributes [object.attributes]")
            end

            def self.associations(obj, log_prefix, handle = $evm)
              return unless ar_object?(obj)
              handle.log("info", " #{log_prefix} Begin Associations [object.associations]")
              obj.associations.sort.each do |assc|
                handle.log("info", "   Associations - #{assc}")
              end
              handle.log("info", " #{log_prefix} End Associations [object.associations]")
            end

            def self.tags(obj, log_prefix, handle = $evm)
              return unless obj.taggable?
              handle.log("info", " #{log_prefix} Begin Tags [object.tags]")
              obj.tags.sort.each do |tag_element|
                tag_text = tag_element.split('/')
                handle.log("info", "    Category:<#{tag_text.first.inspect}> Tag:<#{tag_text.last.inspect}>")
              end
              handle.log("info", " #{log_prefix} End Tags [object.tags]")
            end
          end
        end
      end
    end
  end
end
