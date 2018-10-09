module ManageIQ
  module Automate
    module Transformation
      module TransformationHosts
        module Common
          class Utils
            DEFAULT_EMS_MAX_RUNNERS = 10

            def self.transformation_hosts(ems, handle = $evm)
              handle.vmdb(:conversion_host).all.select { |ch| ch.ext_management_system == ems }
            end

            def self.eligible_transformation_hosts(ems, handle = $evm)
              transformation_hosts(ems, handle).select { |ch| ch.eligible? }.sort_by { |ch| ch.active_tasks.size }
            end

            def self.get_runners_count_by_ems(ems, handle = $evm)
              transformation_hosts(ems, handle).inject(0) { |sum, ch| sum + ch.active_tasks.size }
            end

            def self.ems_max_runners(ems, factory_config, max_runners = DEFAULT_EMS_MAX_RUNNERS)
              if ems.custom_get('Max Transformation Runners')
                ems.custom_get('Max Transformation Runners').to_i
              elsif factory_config['ems_max_runners']
                factory_config['ems_max_runners'].to_i
              else
                max_runners
              end
            end

            def self.get_transformation_host(task, factory_config, handle = $evm)
              ems = task.destination_ems
              ems_cur_runners = get_runners_count_by_ems(ems, handle)
              return unless ems_cur_runners < ems_max_runners(ems, factory_config)
              thosts = eligible_transformation_hosts(ems, handle)
              return if thosts.size.zero?
              thosts.first
            end
          end
        end
      end
    end
  end
end
