module ManageIQ
  module Automate
    module System
      module CommonMethods
        module MiqAe
          class WeightedUpdateStatus
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
            def reconcile_states_percent(path, states)
              direct_children = states.reject { |k, _| k.gsub(/^#{path}\//, '').include?('/') }
              return states[path]['percent'] if direct_children.empty?
              percent = 0
              direct_children.each_key { |dc_path| percent += reconcile_states_percent(dc_path, states).to_f * states[dc_path]['weight'].to_f / 100.0 }
              percent
            end

            def on_entry(state_hash, _, _, state_weight, state_description)
              # Initiate the state hash if it doesn't exist yet
              state_hash ||= { 'status' => 'active', 'weight' => state_weight, 'description' => state_description, 'message' => state_description }
              # Add the start date and set percentage to 0 if entering the
              # state for the first time (retries count == 0)
              if @handle.root['ae_state_retries'].to_i.zero?
                state_hash['started_on'] = Time.now.utc
                state_hash['percent'] = 0.0
              end
              state_hash
            end

            def on_exit(state_hash, state_progress, state_name, _, _)
              # If the state is retrying, we leave the status to 'active'.
              if @handle.root['ae_result'] == 'retry'
                # If the method provides progress info, it is merged, otherwise we set
                # it based on current retry and max retries.
                if state_progress.nil?
                  state_hash['message'] = "#{state_name} is not finished yet [#{@handle.root['ae_state_retries']}/#{@handle.root['ae_state_max_retries']} retries]."
                  state_hash['percent'] = @handle.root['ae_state_retries'].to_f / @handle.root['ae_state_max_retries'].to_f * 100.0
                else
                  # We also merge the potential message from method.
                  state_hash.merge!(state_progress)
                end
              # If we don't retry, it means that the state is finished, so  We also merge
              # the potential message from method.
              else
                # We set status to 'finished' and percentage to 100.
                state_hash['status'] = 'finished'
                state_hash['percent'] = 100.0
                state_hash['message'] = state_progress.nil? ? "#{state_name} is finished." : state_progress['message']
              end
              # Then, we set the update time to now, which is also finish time
              # when the state is finished.
              state_hash['updated_on'] = Time.now.utc
              state_hash
            end

            def on_error(state_hash, state_progress, _, _, state_description)
              # The state has failed, so we consider it as finished and 100%.
              state_hash['status'] = 'failed'
              state_hash['percent'] = 100.0
              # We merge the potential message from method and set the update time.
              state_hash['message'] = state_progress.nil? ? "Failed to #{state_description}." : state_progress['message']
              state_hash['updated_on'] = Time.now.utc
              state_hash
            end

            def main
              vmdb_object_type = @handle.root['vmdb_object_type']
              if vmdb_object_type =~ /^service_template_[\w\d]+_task$/
                task = @handle.root[vmdb_object_type]
                raise @handle.root.attributes.inspect if task.nil?
                unless task.nil?
                  # Initiate the task progress hash if it doesn't exist yet
                  progress = task.get_option(:progress) || { 'current_state' => '', 'current_description' => '', 'percent' => 0.0, 'states' => {} }

                  # Collect the state details
                  state_name = @handle.root['ae_state']
                  state_ancestry = @handle.object['state_ancestry'].to_s
                  state_description = @handle.inputs['description'] || state_name
                  state_weight = @handle.inputs['weight'] || 0

                  # Updating the current state hash with method progress
                  state_hash = send(
                    @handle.root['ae_state_step'],
                    progress['states']["#{state_ancestry}/#{state_name}"],
                    @handle.get_state_var('ae_state_progress'),
                    state_name,
                    state_weight,
                    state_description
                  )
                  @handle.log(:info, "State Hash: #{state_hash.inspect}")

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
                    progress['percent'] = reconcile_states_percent('', progress['states']).round(2)
                  end
                  # We clear the ae_state_progress state var
                  @handle.set_state_var('ae_state_progress', nil)
                  # We record the progress as a task option.
                  task.update_transformation_progress(progress)
                  # We set the task message.
                  if @handle.root['ae_state_step'] == 'on_error'
                    task.message = 'Failed'
                  else
                    task.message = @handle.inputs['task_message'] unless @handle.inputs['task_message'] == '_'
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

if $PROGRAM_NAME == __FILE__
  ManageIQ::Automate::System::CommonMethods::MiqAe::WeightedUpdateStatus.new.main
end
