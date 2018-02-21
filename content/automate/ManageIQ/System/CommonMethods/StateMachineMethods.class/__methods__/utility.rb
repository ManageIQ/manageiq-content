#
# Embedded method example that normalizes a vm name
#
module ManageIQ
  module Automate
    module System
      module CommonMethods
        module StateMachineMethods
          class Utility
            # Class Method
            def self.normalize_name(name)
              raise ArgumentError, "name is nil" unless name
              name.gsub(/[.?+-]/, '_')
            end

            # Constructor
            def initialize(name)
              @name = name
            end

            # Instance Method, that calls the class method
            def normalize
              self.class.normalize_name(@name)
            end
          end
        end
      end
    end
  end
end
