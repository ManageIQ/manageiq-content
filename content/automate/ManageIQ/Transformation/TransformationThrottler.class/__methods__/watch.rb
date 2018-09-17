module ManageIQ
  module Automate
    module Transformation
      module TransformationThrottler
        class Watch
          def initialize(handle = $evm)
            @handle = handle
            @active_throttlers = ManageIQ::Automate::Transformation::TransformationThrottler::Utils.active_throttlers(@handle)
          end

          def main
            ManageIQ::Automate::Transformation::TransformationThrottler::Utils.launch(@handle) if @active_throttlers.empty?
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Transformation::TransformationThrottler::Watch.new.main
