module ManageIQ
  module Automate
    module Transformation
      module TransformationHosts
        module Common
          class Utils
            DEFAULT_EMS_MAX_RUNNERS = 10
            DEFAULT_HOST_MAX_RUNNERS = 10

            def self.get_runners_count_by_host(host, handle = $evm)
              handle.vmdb(:service_template_transformation_plan_task).where(:state => 'active').select { |task| task.get_option(:transformation_host_id) == host.id }.size
            end

            def self.host_max_runners(host, factory_config, max_runners = DEFAULT_HOST_MAX_RUNNERS)
              if host.custom_get('Max Transformation Runners')
                host.custom_get('Max Transformation Runners').to_i
              elsif factory_config['transformation_host_max_runners']
                factory_config['transformation_host_max_runners'].to_i
              else
                max_runners
              end
            end

            def self.transformation_hosts(ems, factory_config, handle = $evm)
              thosts = []
              ems.hosts.each do |host|
                next unless host.tagged_with?('v2v_transformation_host', 'true')
                thosts << {
                  :type                  => 'OVirtHost',
                  :transformation_method => host.tags('v2v_transformation_method'),
                  :host                  => host,
                  :runners               => {
                    :current => get_runners_count_by_host(host, handle),
                    :maximum => host_max_runners(host, factory_config)
                  }
                }
              end
              thosts.sort_by! { |th| th[:runners][:current] }
            end

            def self.eligible_transformation_hosts(ems, factory_config, handle = $evm)
              transformation_hosts(ems, factory_config, handle).select { |thost| thost[:runners][:current] < thost[:runners][:maximum] }
            end

            def self.get_runners_count_by_ems(ems, factory_config, handle = $evm)
              transformation_hosts(ems, factory_config, handle).inject(0) { |sum, thost| sum + thost[:runners][:current] }
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
              ems = handle.vmdb(:ext_management_system).find_by(:id => task.get_option(:destination_ems_id))
              ems_cur_runners = get_runners_count_by_ems(ems, factory_config, handle)
              return unless ems_cur_runners < ems_max_runners(ems, factory_config)
              thosts = eligible_transformation_hosts(ems, factory_config, handle)
              return if thosts.size.zero?
              [thosts.first[:type], thosts.first[:host], thosts.first[:transformation_method]]
            end
          end
        end
      end
    end
  end
end
