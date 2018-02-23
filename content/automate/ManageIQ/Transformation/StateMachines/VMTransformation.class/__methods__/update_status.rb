module Transformation
  module StateMachines
    module VMTransformation
      class UpdateStatus
        def initialize(handle = $evm)
          @handle = handle
        end

        # This method gets the current state, even in the context of nested
        # state machines. Where running a nested state machines, there can be
        # more than one active states: one per level of nesting. The real
        # active state is the one with the deepest ancestry.
        def current_state(states)
          active_states = states.select { |_, v| v['status'] == 'active' }.keys
          states_depth = active_states.map { |state| state.split('/').length }
          active_states[states_depth.index(states_depth.max)]
        end

        # This method recusrively collects the progress of children states
        # and weight them, to finally weight the result with the current state
        # weight.
        def reconcile_children_percent(path, states)
          children = states.reject { |k, _| k.gsub(/^#{path}\//, '').include?('/') }
          if children.empty?
            percent = states[path]['percent'].to_f * states[path]['weight'].to_f / 100.to_f
          else
            percent = 0
            children.each_key { |child| percent += reconcile_children_percent(child, states).to_f * children[child]['weight'].to_f / 100.to_f }
          end
        end

        def main
          task = @handle.root['service_template_transformation_plan_task']
          unless task.nil?
            # Initiate the task progress hash if it doesn't exist yet
            progress = task.get_option(:progress) || { 'current_state' => '', 'current_description' => '', 'percent' => 0, 'states' => {} }

            # Collect the state details
            state_name = @handle.root['ae_state']
            state_ancestry = @handle.object['state_ancestry'].to_s
            state_description = @handle.inputs['state_description'] == '_' ? state_name : @handle.inputs['state_description']
            state_weight = @handle.inputs['state_weight']

            # Get the current state hash if it already exists
            state_hash = progress['states']["#{state_ancestry}/#{state_name}"]

            # Get the state progress data provided by the state method
            state_progress = @handle.get_state_var('ae_state_progress')
            
            # Aggregate the state progress in the state hash based on state
            # phase (entry, exit, error). This updates the details with live
            # data from the method, and also sets sane defaults.
            case @handle.root['ae_status_state']
            when 'on_entry'
              # Initiate the state hash if it doesn't exist yet
              state_hash ||= { 'status' => 'active', 'weight' => state_weight, 'description' => state_description, 'message' => state_description }
              # Add the start date and set percentage to 0 if entering the
              # state for the first time (retries count == 0)
              if @handle.root['ae_state_retries'].to_i.zero?
                state_hash['started_on'] = Time.now.utc
                state_hash['percent'] = 0
              end
            when 'on_exit'
              # If the state is retrying, we leave the status to 'active' and
              # update the percentage. If the method provides progress info,
              # it is merged, otherwise we set it based on current retry and
              # max retries. We also merge the potential message from method.
              if @handle.root['ae_result'] == 'retry'
                if state_progress.nil?
                  state_hash['message'] = "#{state_name} is not finished yet, retrying in #{@handle.root['ae_retry_interval']} seconds."
                  state_hash['percent'] = @handle.root['ae_state_retries'].to_f / @handle.root['ae_max_retries'].to_f * 100.to_f
                else
                  state_hash.merge!(state_progress)
                end
              # If we don't retry, it means that the state is finished, so we
              # set percentage to 100 and status to 'finished'. We also merge
              # the potential message from method.
              else
                state_hash['status'] = 'finished'
                state_hash['percent'] = 100
                state_hash['message'] = state_progress.nil? ? "#{state_name} is finished, moving on." : state_progress['message']
              end
              # Then, we set the update time to now, which is also finish time
              # when the state is finished.
              state_hash['updated_on'] = Time.now.utc
            when 'on_error'
              # The state has failed and we consider it as finished and 100%.
              # We also merge the potential message from method and set the
              # update time.
              state_hash['status'] = 'finished'
              state_hash['percent'] = 100
              state_hash['message'] = state_progress.nil? ? "#{state_name} has failed, moving on." : state_progress['message']
              state_hash['updated_on'] = Time.now.utc
            end

            # We record the state hash in the task progress
            progress['states']["#{state_ancestry}/#{state_name}"] = state_hash
            # If we enter the state, we update the task progress with current
            # state and description.
            if @handle.root['ae_status_state'] == 'on_entry'
              progress['current_state'] = current_state(progress['states'])
              progress['current_description'] = progress['states'][progress['current_state']]['description']
            # End if we exit/error the state, we update the percentage based on
            # children states and current state weight.
            else
              progress['percent'] = reconcile_children_percent('', progress['states'])
            end
            # We record the progress as a task option.
            task.set_option(:progress, progress)
          end
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  Transformation::StateMachines::VMTransformation::UpdateStatus.new.main
end
