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
              #return thosts.first[:type], thosts.first[:host], thosts.first[:transformation_method]
              [thosts.first[:type], thosts.first[:host], thosts.first[:transformation_method]]
            end

            def self.virtv2vwrapper_options(task)
              send("virtv2vwrapper_options_#{task.get_option(:transformation_type)}_#{task.get_option(:transformation_method)}", task)
            end

            def self.vmware_uri_vddk(vm)
              URI::Generic.build(
                :scheme   => 'esx',
                :userinfo => CGI.escape(vm.host.authentication_userid),
                :host     => vm.host.ipaddress,
                :path     => '/',
                :query    => { :no_verify => 1 }.to_query
              ).to_s
            end
            private_class_method :vmware_uri_vddk

            # We can't put the whole storage and VM location bits in the URI
            # build, as is contains _invalid_ characters, such as space and [.
            def self.vmware_uri_ssh(vm, storage)
              url = URI::Generic.build(
                :scheme   => 'ssh',
                :userinfo => 'root',
                :host     => vm.host.ipaddress,
                :path     => "/vmfs/volumes"
              ).to_s
              url += "/#{storage.name}/#{vm.location}"
            end
            private_class_method :vmware_uri_ssh

            def self.rhv_url(ems)
              URI::Generic.build(
                :scheme => 'https',
                :host   => ems.hostname,
                :path   => '/ovirt-engine/api'
              ).to_s
            end
            private_class_method :rhv_url

            def self.virtv2vwrapper_options_vmwarews2rhevm_vddk(task)
              source_vm = task.source
              source_cluster = source_vm.ems_cluster

              destination_cluster = task.transformation_destination(source_cluster)
              destination_ems = destination_cluster.ext_management_system
              destination_storage = task.transformation_destination(source_vm.hardware.disks.select { |d| d.device_type == 'disk' }.first.storage)

              {
                :vm_name             => source_vm.name,
                :transport_method    => 'vddk',
                :vmware_fingerprint  => ManageIQ::Automate::Transformation::Infrastructure::VM::VMware::Utils.host_fingerprint(source_vm.host),
                :vmware_uri          => vmware_uri_vddk(source_vm),
                :vmware_password     => source_vm.host.authentication_password,
                :rhv_url             => rhv_url(destination_ems),
                :rhv_cluster         => destination_cluster.name,
                :rhv_storage         => destination_storage.name,
                :rhv_password        => destination_ems.authentication_password,
                :source_disks        => task[:options][:virtv2v_disks].map { |disk| disk[:path] },
                :network_mappings    => task[:options][:virtv2v_networks],
                :install_drivers     => true,
                :insecure_connection => true
              }
            end
            private_class_method :virtv2vwrapper_options_vmwarews2rhevm_vddk

            def self.virtv2vwrapper_options_vmwarews2rhevm_ssh(task)
              source_vm = task.source
              source_cluster = source_vm.ems_cluster
              source_storage = source_vm.hardware.disks.select { |d| d.device_type == 'disk' }.first.storage

              destination_cluster = task.transformation_destination(source_cluster)
              destination_ems = destination_cluster.ext_management_system
              destination_storage = task.transformation_destination(source_vm.hardware.disks.select { |d| d.device_type == 'disk' }.first.storage)

              {
                :vm_name             => vmware_uri_ssh(source_vm, source_storage),
                :transport_method    => 'ssh',
                :rhv_url             => rhv_url(destination_ems),
                :rhv_cluster         => destination_cluster.name,
                :rhv_storage         => destination_storage.name,
                :rhv_password        => destination_ems.authentication_password,
                :source_disks        => task[:options][:virtv2v_disks].map { |disk| disk[:path] },
                :network_mappings    => task[:options][:virtv2v_networks],
                :install_drivers     => true,
                :insecure_connection => true
              }
            end
            private_class_method :virtv2vwrapper_options_vmwarews2rhevm_ssh

            def self.remote_command(task, transformation_host, command, stdin = nil, run_as = nil)
              "ManageIQ::Automate::Transformation::TransformationHosts::#{task.get_option(:transformation_host_type)}::Utils".constantize.remote_command(transformation_host, command, stdin, run_as)
            end
          end
        end
      end
    end
  end
end
