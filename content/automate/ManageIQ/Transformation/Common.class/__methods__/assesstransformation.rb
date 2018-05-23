module ManageIQ
  module Automate
    module Transformation
      module Common
        class AssessTransformation
          SUPPORTED_SOURCE_EMS_TYPES = ['vmwarews'].freeze
          SUPPORTED_DESTINATION_EMS_TYPES = ['rhevm'].freeze
          REQUIRED_CUSTOM_ATTRIBUTES = {
            'rhevm' => [:rhv_export_domain_id, :rhv_cluster_id, :rhv_storage_domain_id]
          }.freeze

          def initialize(handle = $evm)
            @handle = handle
          end

          def main
            begin
              task = @handle.root['service_template_transformation_plan_task']
              raise 'No task found. Exiting' if task.nil?
              @handle.log(:info, "Task: #{task.inspect}") if @debug

              source_vm ||= task.source
              raise 'No VM found. Exiting' if source_vm.nil?

              source_cluster = source_vm.ems_cluster
              destination_cluster = task.transformation_destination(source_cluster)
              raise "No destination cluster for '#{source_vm.name}'. Exiting." if destination_cluster.nil?

              source_ems = source_vm.ext_management_system
              destination_ems = destination_cluster.ext_management_system

              virtv2v_networks = []
              source_vm.hardware.nics.select { |n| n.device_type == 'ethernet' }.each do |nic|
                source_network = nic.lan
                destination_network = task.transformation_destination(source_network)
                raise "[#{source_vm.name}] NIC #{nic.device_name} [#{source_network.name}] has no mapping. Aborting." if destination_network.nil?
                virtv2v_networks << { source: source_network.name, destination: destination_network.name }
              end
              @handle.log(:info, "Network mappings: #{virtv2v_networks}")
              task.set_option(:virtv2v_networks, virtv2v_networks)
              
              virtv2v_disks = []
              source_vm.hardware.disks.select { |d| d.device_type == 'disk' }.each do |disk|
                source_storage = disk.storage
                destination_storage = task.transformation_destination(disk.storage)
                raise "[#{source_vm.name}] Disk #{disk.device_name} [#{source_storage.name}] has no mapping. Aborting." if destination_storage.nil?
                virtv2v_disks << { path: disk.filename, size: disk.size, percent: 0, weight: disk.size / source_vm.allocated_disk_storage * 100 }
              end
              @handle.log(:info, "Source VM Disks #{virtv2v_disks}")
              task.set_option(:virtv2v_disks, virtv2v_disks)
              
              raise "Unsupported source EMS type: #{source_ems.emstype}." unless SUPPORTED_SOURCE_EMS_TYPES.include?(source_ems.emstype)
              @handle.set_state_var(:source_ems_type, source_ems.emstype)

              raise "Unsupported destination EMS type: #{destination_ems.emstype}." unless SUPPORTED_DESTINATION_EMS_TYPES.include?(destination_ems.emstype)
              @handle.set_state_var(:destination_ems_type, destination_ems.emstype)

              transformation_type = "#{source_ems.emstype}2#{destination_ems.emstype}"
              @handle.set_state_var(:transformation_type, transformation_type)

              transformation_method = "vddk"
              @handle.set_state_var(:transformation_method, transformation_method)

              transformation_host_type = "ovirt_host"
              @handle.set_state_var(:transformation_host_type, transformation_host_type)

              factory_config = {
                'vmtransformation_check_interval' => @handle.object['vmtransformation_check_interval'] || '15.seconds',
                'vmpoweroff_check_interval' => @handle.object['vmpoweroff_check_interval'] || '30.seconds'
              }
              @handle.set_state_var(:factory_config, factory_config)

              # Force VM shutdown and snapshots collapse by default
              task.set_option(:collapse_snapshots, true)
              task.set_option(:power_off, true)
            rescue Exception => e
              @handle.set_state_var(:ae_state_progress, { 'message' => e.message })
              raise
            end
          end
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  ManageIQ::Automate::Transformation::Common::AssessTransformation.new.main
end
