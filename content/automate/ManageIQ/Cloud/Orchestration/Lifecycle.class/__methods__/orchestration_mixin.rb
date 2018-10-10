#
# Description: common methods needed when working with OrchestrationStacks.
#
module ManageIQ
  module Automate
    module Cloud
      module Orchestration
        module Lifecycle
          module OrchestrationMixin
            def get_stack(handle)
              return unless handle
              stack = get_stack_from(handle, :object) || get_stack_from(handle, :root) || get_service(handle).try(:orchestration_stack)
              handle.log(:info, 'Could not find related stack') unless stack
              stack
            end

            def get_service(handle)
              return unless handle
              if (service = handle.object['service'])
                handle.log(:info, "Fetched service from $evm.object['service']")
                service
              elsif (service = handle.root['service'])
                handle.log(:info, "Fetched service from $evm.root['service']")
                service
              else
                handle.log(:info, 'Could not find related service')
                nil
              end
            end

            def get_stack_from(handle, object_name)
              return unless handle && (object = handle.try(object_name))
              if (stack = object['orchestration_stack'])
                handle.log(:info, "Fetched stack from $evm.#{object_name}['orchestration_stack']")
                stack
              elsif (stack_id = object['orchestration_stack_id'].to_i) && stack_id != 0 &&
                    (stack = handle.vmdb('orchestration_stack', stack_id))
                handle.log(:info, "Fetched stack from $evm.#{object_name}['orchestration_stack_id']")
                stack
              end
            end
          end
        end
      end
    end
  end
end
