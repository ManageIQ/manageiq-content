module ManageIQ
  module Automate
    module Transformation
      module TransformationThrottler
        class Throttle
          def initialize(handle = $evm)
            @handle = handle
          end

          def main
            return unless ManageIQ::Automate::Transformation::TransformationThrottler::Utils.elected_throttler?(@handle)
            ManageIQ::Automate::Transformation::TransformationThrottler::Utils.schedule_tasks(@handle)
            ManageIQ::Automate::Transformation::TransformationThrottler::Utils.adjust_limits(@handle)
            ManageIQ::Automate::Transformation::TransformationThrottler::Utils.retry_or_die(@handle)
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Transformation::TransformationThrottler::Throttle.new.main
