#
# 
#

module Transformation
  module TransformationHost
    module Common
      class Utils
        def initialize(handle = $evm)
          @debug = true
          @handle = handle
        end

        def get_transformation_hosts(ems)
          ems.hosts.select { |host| host.tagged_with('mf_transformation_host', 'true') }
        end
        
        def get_runners_count_by_host(host)
          return @handle.vmdb(:vm).all.select { |v| v.custom_get('Transformation Host') == host.name }.size
        end
        
        def get_runners_count_by_ems(ems)
          total_runners = 0
          get_transformation_hosts.each { |host| total_runners += get_runners_count_by_host(host) }
          return total_runners
        end

        def set_transformation_host(vm, ems, factory_config)
          # Determine the least utilized conversion host
          min_runners, transformation_host = nil, nil
          
          get_transformation_hosts.each do |host|
            runners_count = get_runners_count_by_host(host)
            max_runners = host.custom_get('Max Transformation Runners')
            max_runners = factory_config['transformation_host_max_runners'] if max_runners.blank?
            next if runners_count == max_runners
            ( transformation_host = host ; break ) if runners_count == 0
            if transformation_host.nil? || runners_count < min_runners
              transformation_host = host
              min_runners = runners_count
            end
          end
          if transformation_host.nil?
            @handle.log(:info, "No transformation host found.")
          else
            @handle.log(:info, "Least busy transformation host: #{transformation_host}")
            vm.custom_set('Transformation Host', transformation_host.guid)
          end
          return transformation_host
        end
        
        def unset_transformation_host(vm)
          vm.custom_set('Transformation Host', nil)
        end
        
        def main
          
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  Transformation::TransformationHost::Common::Utils.new.main
end
