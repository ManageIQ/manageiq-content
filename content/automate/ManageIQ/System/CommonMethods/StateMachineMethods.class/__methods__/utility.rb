#
# Embedded method example that normalizes a vm name
#
module ManageIQ
  module Automate
    module System
      module CommonMethods
        module StateMachineMethods
          class Utility
            def self.normalize_name(name)
              raise InvalidArguments, "name is nil" unless name
              name.gsub(/[.?+-]/, '_')
            end
          end
        end
      end
    end
  end
end
