module ManageIQ
  module Automate
    module Transformation
      module TransformationHost
        module OVirtHost
          class VMCheckTransformed_vmwarews2rhevm_vddk
            def initialize(handle = $evm)
              @debug = true
              @handle = handle
            end

            def main
              begin
                require 'json'
              
                factory_config = @handle.get_state_var(:factory_config)
                raise "No factory config found. Aborting." if factory_config.nil?

                task = @handle.root['service_template_transformation_plan_task']
                source_vm = task.source

                # Get the virt-v2v start timestamp
                start_timestamp = task.get_option(:virtv2v_started_on)

                # Retrieve transformation host
                transformation_host = @handle.vmdb(:host).find_by(:id => task.get_option(:transformation_host_id))

                # Retrieve state of virt-v2v
                result = Transformation::TransformationHosts::OVirtHost::Utils.remote_command(transformation_host, "cat '#{task.get_option(:virtv2v_wrapper)['state_file']}'")
                raise result[:stderr] unless result[:success] and not result[:stdout].empty?
                virtv2v_state = JSON.parse(result[:stdout])
                @handle.log(:info, "VirtV2V State: #{virtv2v_state.inspect}")

                # Retrieve disks array
                virtv2v_disks = task.get_option(:virtv2v_disks)
                virtv2v_disks = [virtv2v_disks] if virtv2v_disks.is_a?(Hash)
                @handle.log(:info, "Disks: #{virtv2v_disks.inspect}")

                if virtv2v_state['finished'].nil?
                  # Update the progress of each disk
                  virtv2v_disks.each do |disk|
                    matching_disks = virtv2v_state['disks'].select { |d| d['path'] == disk[:path] }
                    raise "No disk matches '#{disk[:path]}'. Aborting." if matching_disks.length.zero?
                    raise "More than one disk matches '#{disk[:path]}'. Aborting." if matching_disks.length > 1
                    disk[:percent] = matching_disks.first['progress']
                  end
                  converted_disks = virtv2v_disks.select { |d| not d[:percent].zero? }
                  @handle.log(:info, "Converted disks: #{converted_disks.inspect}")
                  if converted_disks.empty?
                    @handle.set_state_var(:ae_state_progress, { 'message' => "Disks transformation is initializing.", 'percent' => 1 })
                  else
                    percent = 0
                    converted_disks.each { |disk| percent += ( disk[:percent].to_f * disk[:weight].to_f / 100.0 ) }
                    message = "Converting disk #{converted_disks.length} / #{virtv2v_disks.length} [#{percent.round(2)}%]."
                    @handle.set_state_var(:ae_state_progress, { 'message' => message, 'percent' => percent.round(2) })
                  end
                else
                  task.set_option(:virtv2v_finished_on, Time.now.strftime('%Y%m%d_%H%M'))
                  if virtv2v_state['return_code'].zero?
                    virtv2v_disks.each { |d| d[:percent] = 100 }
                    @handle.set_state_var(:ae_state_progress, { 'message' => 'Disks transformation succeeded.', 'percent' => 100 })
                  else
                    @handle.set_state_var(:ae_state_progress, { 'message' => 'Disks transformation succeeded.'})
                    raise "Disks transformation failed."
                  end
                end

                task.set_option(:virtv2v_disks, virtv2v_disks)

                if task.get_option(:virtv2v_finished_on).nil?
                  @handle.root['ae_result'] = 'retry'
                  @handle.root['ae_retry_server_affinity'] = true
                  @handle.root['ae_retry_interval'] = factory_config['vmtransformation_check_interval'] || '15.seconds'
                  @handle.log(:info, "Disk transformation is not finished. Checking in #{@handle.root['ae_retry_interval']}")
                end
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
end

if $PROGRAM_NAME == __FILE__
  ManageIQ::Automate::Transformation::TransformationHost::OVirtHost::VMCheckTransformed_vmwarews2rhevm_vddk.new.main
end
