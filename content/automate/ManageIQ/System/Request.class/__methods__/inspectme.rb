#
# Description: Log all objects stored in the $evm.root hash.
#        Then log the attributes, associations, tags and
#        virtual_columns for each automate service model.
#

module ManageIQ
  module Automate
    module System
      module Request
        class Inspectme
          def initialize(handle = $evm)
            @handle = handle
          end

          def main
            ManageIQ::Automate::System::CommonMethods::Utils::LogObject.root(@handle)
            ManageIQ::Automate::System::CommonMethods::Utils::LogObject.log_ar_objects("Inspectme", @handle)
          end
        end
      end
    end
  end
end

ManageIQ::Automate::System::Request::Inspectme.new.main
