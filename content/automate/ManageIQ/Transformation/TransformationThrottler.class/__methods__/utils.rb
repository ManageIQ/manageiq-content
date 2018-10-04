module ManageIQ
  module Automate
    module Transformation
      module TransformationThrottler
        class Utils
          NAMESPACE = 'Transformation/StateMachines'.freeze
          CLASS_NAME = 'TransformationThrottler'.freeze
          DEFAULT_THROTTLER_ELECTION_POLICY = 'eldest_active'.freeze
          DEFAULT_THROTTLER_TYPE = 'Default'.freeze
          DEFAULT_THROTTLER_TTL = 3600
          DEFAULT_TASKS_SCHEDULING_POLICY = 'fifo'.freeze
          DEFAULT_LIMITS_ADJUSTMENT_POLICY = 'skip'.freeze

          def self.log_and_raise(message, handle = $evm)
            handle.log(:error, message)
            raise "ERROR - #{message}"
          end

          def self.task(handle = $evm)
            @task ||= handle.root['automation_task'].tap do |task|
              log_and_raise('An automation_task is needed for this method to continue', handle) if task.nil?
            end
          end

          def self.current_throttler(handle = $evm)
            @current_throttler ||= task(handle).miq_request.tap do |request|
              log_and_raise('A miq_request is needed for this method to continue', handle) if request.nil?
            end
          end

          def self.active_throttlers(handle = $evm)
            @active_throttlers ||= handle.vmdb(:miq_request).where(
              :request_state => 'active',
              :type          => 'AutomationRequest'
            ).select do |request|
              request.options[:namespace] == NAMESPACE &&
                request.options[:class_name] == CLASS_NAME &&
                request.options[:instance_name] == throttler_type(handle)
            end
          end

          def self.throttler_election_policy(handle = $evm)
            @throttler_election_policy ||= handle.root['throttler_election_policy'] || DEFAULT_THROTTLER_ELECTION_POLICY
          end

          def self.elected_throttler?(handle = $evm)
            send("#{throttler_election_policy(handle)}_throttler?", handle)
          end

          def self.eldest_active_throttler?(handle = $evm)
            active_throttlers(handle).select { |t| t.created_on < current_throttler(handle).created_on }.length.zero?
          end

          def self.throttler_ttl(handle = $evm)
            @throttler_ttl ||= handle.root['throttler_ttl'] || DEFAULT_THROTTLER_TTL
          end

          def self.throttler_type(handle = $evm)
            @throttler_type ||= handle.root['throttler_type'] || DEFAULT_THROTTLER_TYPE
          end

          def self.launch(handle = $evm)
            handle.execute(
              :create_automation_request,
              {
                :namespace     => NAMESPACE,
                :class_name    => CLASS_NAME,
                :instance_name => throttler_type(handle),
                :user_id       => handle.vmdb(:user).find_by(:userid => 'admin').id,
                :attrs         => { :ttl => throttler_ttl(handle) }
              },
              'admin',
              true
            )
          end

          def self.retry_or_die(handle = $evm)
            return if current_throttler(handle).created_on.utc + throttler_ttl(handle) < Time.now.utc
            return if active_transformation_tasks(handle).empty?
            handle.root['ae_result'] = 'retry'
            handle.root['ae_retry_interval'] = (throttler_ttl(handle) / handle.root['ae_state_max_retries']).seconds
          end

          def self.tasks_scheduling_policy(handle = $evm)
            @tasks_scheduling_policy ||= handle.root['tasks_scheduling_policy'] || DEFAULT_TASKS_SCHEDULING_POLICY
          end

          def self.schedule_tasks(handle = $evm)
            send("schedule_tasks_#{tasks_scheduling_policy(handle)}", handle)
          end

          def self.schedule_tasks_fifo(handle = $evm)
            unassigned_transformation_tasks(handle).sort_by(&:created_on).each do |transformation_task|
              transformation_host_type, transformation_host, transformation_method = ManageIQ::Automate::Transformation::TransformationHosts::Common::Utils.get_transformation_host(transformation_task, {})
              break if transformation_host.nil?
              transformation_task.set_option(:transformation_host_id, transformation_host.id)
              transformation_task.set_option(:transformation_host_name, transformation_host.name)
              transformation_task.set_option(:transformation_host_type, transformation_host_type)
              transformation_task.set_option(:transformation_method, transformation_method)
            end
          end

          def self.limits_adjustment_policy(handle = $evm)
            @limits_adjustment_policy ||= handle.root['limits_adjustment_policy'] || DEFAULT_LIMITS_ADJUSTMENT_POLICY
          end

          def self.adjust_limits(handle = $evm)
            send("adjust_limits_#{limits_adjustment_policy(handle)}", handle)
          end

          def self.adjust_limits_skip(handle = $evm)
          end

          def self.active_transformation_tasks(handle)
            @active_transformation_tasks ||= handle.vmdb(:service_template_transformation_plan_task).where(:state => 'active')
          end

          def self.unassigned_transformation_tasks(handle)
            active_transformation_tasks(handle).select { |transformation_task| transformation_task.get_option(:transformation_host_id).nil? }
          end
        end
      end
    end
  end
end
