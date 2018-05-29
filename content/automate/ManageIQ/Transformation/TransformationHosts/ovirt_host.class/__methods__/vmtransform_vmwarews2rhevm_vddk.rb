module ManageIQ
  module Automate
    module Transformation
      module TransformationHost
        module OVirtHost
          class VMTransform_vmwarews2rhevm_vddk
            def initialize(handle = $evm)
              @debug = false
              @handle = handle
            end

            def main
              begin
                require 'json'

                factory_config = @handle.get_state_var(:factory_config)
                raise "No factory config found. Aborting." if factory_config.nil?

                task = @handle.root['service_template_transformation_plan_task']
                source_vm = task.source
                source_cluster = source_vm.ems_cluster
                source_ems = source_vm.ext_management_system
                destination_cluster = task.transformation_destination(source_cluster)
                destination_ems = destination_cluster.ext_management_system
                destination_storage = task.transformation_destination(source_vm.hardware.disks.select { |d| d.device_type == 'disk' }.first.storage)
                raise "Invalid destination EMS type: #{destination_ems.emstype}. Aborting." unless destination_ems.emstype == "rhevm"

                # Get or create the virt-v2v start timestamp
                start_timestamp = task.get_option(:virtv2v_started_on) || Time.now.utc.strftime('%Y-%m-%d %H:%M:%S')

                # Retrieve transformation host
                transformation_host = @handle.vmdb(:host).find_by(:id => task.get_option(:transformation_host_id))

                @handle.log(:info, "Transformation - Started On: #{start_timestamp}")

                max_runners = destination_ems.custom_get('Max Transformation Runners') || factory_config['max_transformation_runners_by_ems'] || 1
                if Transformation::TransformationHosts::Common::Utils.get_runners_count_by_ems(destination_ems, @handle.get_state_var(:transformation_method), factory_config) >= max_runners
                  @handle.log("Too many transformations running: (#{max_runners}). Retrying.")
                else
                  # Collect the VMware connection information
                  vmware_uri = "vpx://"
                  vmware_uri += "#{source_ems.authentication_userid.gsub('@', '%40')}@#{source_ems.hostname}/"
                  vmware_uri += "#{source_cluster.v_parent_datacenter.gsub(' ', '%20')}/#{source_cluster.name.gsub(' ', '%20')}/#{source_vm.host.uid_ems}"
                  vmware_uri += "?no_verify=1"

                  # Collect information about the disks to convert
                  virtv2v_disks = task[:options][:virtv2v_disks]
                  source_disks = virtv2v_disks.map { |disk| disk[:path] }
                  @handle.log(:info, "Source VM Disks: #{source_disks}")

                  # Collect information about the network mappings
                  virtv2v_networks = task[:options][:virtv2v_networks]
                  @handle.log(:info, "Network mappings: #{virtv2v_networks}")

                  wrapper_options = {
                    :vm_name            => source_vm.name,
                    :transport_method   => 'vddk',
                    :vmware_fingerprint => Transformation::Infrastructure::VM::VMware::Utils.get_vcenter_fingerprint(source_ems),
                    :vmware_uri         => vmware_uri,
                    :vmware_password    => source_ems.authentication_password,
                    :rhv_url            => "https://#{destination_ems.hostname}/ovirt-engine/api",
                    :rhv_cluster        => destination_cluster.name,
                    :rhv_storage        => destination_storage.name,
                    :rhv_password       => destination_ems.authentication_password,
                    :source_disks       => source_disks,
                    :network_mappings   => virtv2v_networks
                  }
                  # WARNING: Enable at your own risk, as it may lead to sensitive data leak
                  # @handle.log(:info, "JSON Input:\n#{JSON.pretty_generate(wrapper_options)}") if @debug

                  @handle.log(:info, "Connecting to #{transformation_host.name} as #{transformation_host.authentication_userid}") if @debug
                  @handle.log(:info, "Executing '/usr/bin/virt-v2v-wrapper.py'")
                  result = Transformation::TransformationHosts::OVirtHost::Utils.remote_command(transformation_host, "/usr/bin/virt-v2v-wrapper.py", wrapper_options.to_json)
                  raise result[:stderr] unless result[:success]

                  # Record the wrapper files path
                  @handle.log(:info, "Command stdout: #{result[:stdout]}") if @debug
                  task.set_option(:virtv2v_wrapper, JSON.parse(result[:stdout]))

                  # Record the status in the task object
                  task.set_option(:virtv2v_started_on, start_timestamp)
                  task.set_option(:virtv2v_status, 'active')
                end

                if task.get_option(:virtv2v_started_on).nil?
                  @handle.root['ae_result'] = 'retry'
                  @handle.root['ae_retry_server_affinity'] = true
                  @handle.root['ae_retry_interval'] = $evm.object['check_convert_interval'] || '1.minutes'
                end
              rescue Exception => e
                @handle.set_state_var(:ae_state_progress, 'message' => e.message)
                raise
              end
            end
          end
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  ManageIQ::Automate::Transformation::TransformationHost::OVirtHost::VMTransform_vmwarews2rhevm_vddk.new.main
end
