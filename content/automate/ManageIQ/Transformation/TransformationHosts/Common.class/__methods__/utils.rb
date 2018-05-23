module ManageIQ
  module Automate
    module Transformation
      module TransformationHosts
        module Common
          class Utils
            def initialize(handle = $evm)
              @debug = true
              @handle = handle
            end
    
            def main
            end

            def self.get_runners_count_by_host(host, handle=$evm)
              handle.vmdb(:service_template_transformation_plan_task).where(:state => 'active').select { |task| task.get_option(:transformation_host) == host }.size
            end

            def self.transformation_hosts(ems, method, factory_config)
              thosts = []
              ems.hosts.each do |host|
                if host.tagged_with?('v2v_transformation_host', 'true') && host.tagged_with?('v2v_transformation_method', method)
                  thosts << {
                    :host => host, 
                    :runners => { 
                      :current => self.get_runners_count_by_host(host), 
                      :maximum => host.custom_get('Max Transformation Runners') || factory_config['transformation_host_max_runners'] || 1
                    }
                  }
                end
              end
              thosts.sort_by! { |th| th[:runners][:current] }
            end
        
            def self.eligible_transformation_hosts(ems, method, factory_config)
              self.transformation_hosts(ems, method, factory_config).select { |thost| thost[:runners][:current] < thost[:runners][:maximum] }
            end
        
            def self.get_runners_count_by_ems(ems, method, factory_config)
              self.transformation_hosts(ems, method, factory_config).inject(0) { |sum, thost| sum + thost[:runners][:current] }
            end

            def self.get_transformation_host(ems, method, factory_config, max_runners=nil)
              ems_max_runners = ems.custom_get('Max Transformation Runners') || factory_config['ems_max_runners'] || 1
              ems_cur_runners = self.get_runners_count_by_ems(ems, method, factory_config)
              transformation_host = ems_cur_runners < ems_max_runners ? self.eligible_transformation_hosts(ems, method, factory_config).first[:host] : nil
              return transformation_host
            end
          end
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  ManageIQ::Automate::Transformation::TransformationHosts::Common::Utils.new.main
end
