#
# 
#

module Transformation
  module TransformationHost
    module OVirtHost
      class TransformVM_vmware2redhat_vddk
        DESTINATION_OUTPUT_TYPES = { 'openstack' => 'local', 'redhat' => 'rhv' }.freeze
        DESTINATION_OUTPUT_FORMATS = { 'openstack' => 'raw', 'redhat' => 'qcow2' }.freeze
        
        def initialize(handle = $evm)
          @debug = true
          @handle = handle
        end
        
        def main
          require 'net/ssh'
          require 'fileutils'

          factory_config = @handle.root['factory_config']
          raise "No factory config found. Aborting." if factory_config.nil?
          
          vm = @handle.root['vm']
          destination_ems = @handle.root['destination_ems']
          destination_ems_type = @handle.root['destination_ems_type']
          raise "Unknown destination EMS type: #{destination_ems_type}. Exiting." unless DESTINATION_OUTPUT_TYPES.keys.include?(destination_ems_type)
          
          finished = false
          
          # Dependent on conversion and volume renaming for skipping since steps are coupled
          if vm.custom_get('Transformation Finish Date') and vm.custom_get('Transformation Status') == 'Success'
            @handle.log(:info, "Transformation already done for #{vm.name}. Skipping.")
            finished = true
          else
            transformation_host = Transformation::Infrastructure::VM::Common::Utils.set_transformation_host(vm, destination_ems, factory_config)
            if transformation_host.nil?
              @handle.log("No transformation host available. Retrying.")
            else
              max_runners = destination_ems.custom_get('Max Transformation Runners') || factory_config['max_transformation_runners_by_ems'] || 1
              if get_runners_count_by_ems(destination_ems) >= max_runners
                @handle.log("Too many transformations running (#{max_runners}). Retrying.")
                Transformation::Infrastructure::VM::Common::Utils.set_transformation_host(vm)
              else
                # Setting directories and files path to track conversion
                base_directory = "#{factory_config['base_directory']}/convert"
                log_directory = "#{base_directory}/#{vm.name}"
                script_directory = "#{factory_config['base_directory']}/tools"
                temp_directory = "#{factory_config['base_directory']}/temp"
                [base_directory,log_directory,temp_directory].each { |dir| FileUtils.mkdir_p(dir, :mode => 0777) }

                # Set the output location mapping based on target EMS type
                destination_output_locations = {
                  'openstack' => "#{@handle.object['openstack_dir_mount']}/convert/#{vm.name}",
                  'redhat' => Transformation::Infrastructure::VM::RedHat::Utils.ems_get_export_domain(destination_ems)
                }
                
                # If the conversion has not started yet, launch it
                if vm.custom_get('Transformation Start Time').nil?
                  @handle.log(:info, "Connecting to #{transformation_host.name} as #{transformation_host.authentication_userid}") if @debug
                  
                  timestamp  = Time.now.strftime('%Y%m%d_%H%M')
                  v2v_log = "#{log_directory}/#{timestamp}-v2v.log"
                  wrapper_log = "#{log_directory}/#{timestamp}-wrapper.log"
                  sysprep_log = nil
                  
                  # Build the command to execute base on target EMS type and OS type
                  ic_link = "vpx://administrator@#{ems.hostname}/#{vm.host.v_owning_datacenter}/#{vm.host.uid_ems}?no_verify=1"
                  # create password file from ems password this is needed for the vddk to login
                  File.write("#{log_location}/.vddk_password", "#{destination_ems.authentication_password}")
                  vddk_password = "#{log_location}/.vddk_password"
                  vcenter_fingerprint = Transformation::Infrastructure::VM::VMware::Utils.get_vcenter_fingerprint(vm.ext_management_system)
                  
                  command   = "nohup #{script_dir}/#{destination_ems_type}_v2v_#{migration_method}.sh"
                  command += " -i #{vcenter_fingerprint} -c #{ic_link} -p #{vddk_password} -v #{vm.name}"
                  command += " -o #{destination_output_locations[destination_ems_type]} -f #{DESTINATION_OUTPUT_FORMATS[destination_ems_type]} -g #{DESTINATION_OUTPUT_TYPES[destination_ems_type]}"
                  command += " -t #{temp_dir} -l #{v2v_log}"
                  if destination_ems_type == 'redhat'
                    rhv_network = vm.custom_get(:network).blank? ? 'undefined' : vm.custom_get(:network)
                    command += " -e #{rhv_network}"
                  end
                  if vm.os_image_name =~ /linux/i
                    sysprep_log = "#{log_directory}/#{timestamp}-sysprep.log"
                    command += " -L #{sysprep_log}"
                    command += " -n #{vm.custom_get(:ip).split(',').length}" unless vm.custom_get(:ip).nil?
                  end
                  command += " > #{wrapper_log} 2>&1 &"
                  
                  @handle.log(:info, "Executing : #{command}")
                  Net::SSH.start(transformation_host.name, transformation_host.authentication_userid, :password => transformation_host.authentication_password) do |ssh|
                    ssh.exec!(command)
                  end
                  vm.custom_set('Transformation Start Time', timestamp)
                  vm.custom_set('Transformation Status', 'Running')
                  vm.custom_set('Transformation Status Message', 'Transformation initiated')
                else
                  timestamp = vm.custom_get('Transformation Start Time')
                  v2v_log = "#{log_directory}/#{timestamp}-v2v.log"
                  wrapper_log = "#{log_directory}/#{timestamp}-wrapper.log"
                  sysprep_log = "#{log_directory}/#{timestamp}-sysprep.log" if vm.os_image_name =~ /linux/i
                  
                  result = File.open(wrapper_log, 'r').to_a.last
                  @handle.log(:info, "Last line of #{wrapper_log}: #{result}")
                  if result =~ /Stop time/
                    # Checking both logs. v2v_log for success and sysprep_log for error.
                    v2v_success = File.open(v2v_log, 'r').each_line.lazy.detect { |line| /Finishing off/i.match(line) }
                    @handle.log(:info, "Line from #{v2v_log} containing 'Finishing off' : #{v2v_success}")
                    sysprep_success = nil
                    unless sysprep_log.nil?
                      sysprep_error = File.open(sysprep_log, 'r') { |f| f.each_line.detect { |line| /error/i.match(line) } }
                      @handle.log(:info, "Line from #{sysprep_log} containing 'error' : #{sysprep_error}") if sysprep_error
                    end
                    # We want v2v success and don't want sysprep error
                    if not v2v_success.nil? and sysprep_error.nil?
                      vm.custom_set('Transformation Finish Time', Time.now.strftime('%Y%m%d_%H%M'))
                      vm.custom_set('Transformation Status', 'Success')
                      vm.custom_set('Transformation Status Message', 'Successfully converted')
                      @handle.log(:info, 'Successfully ran transformation. Cleaned up counter file and attributes.')
                      finished = true
                    else
                      # Logging is done and Finishing off was not found in v2v log or error was found in sysprep log, so it errored.
                      # Clean up and raise exception.
                      vm.custom_set('Transformation Finish Time', Time.now.strftime('%Y%m%d_%H%M'))
                      vm.custom_set('Transformation Status', 'Failed')
                      vm.custom_set('Transformation Status Message', 'Transformation failed')
                      raise 'Transformation of #{vm.name} failed. Aborting.'
                    end
                  else
                    volume_converting = File.open(vm.custom_get(:v2v_log), 'r').each_line.lazy.select { |l| l.include?('qemu-img convert') }.to_a.last.chomp.split(/\//).last.chop
                    progress = File.open(vm.custom_get(:v2v_log), 'r').to_a.last.split(/\r/).last.strip.match(/\((.*)%\)/)
                    progress=result.split(/\r/).last.strip.match(/\((.*)%\)/)
                    vm.custom_set('Transformation Status Message', progress)
                  end
                end
              end
            end
            
            unless finished
              @handle.root['ae_result'] = 'retry'
              @handle.root['ae_retry_interval'] = $evm.object['check_convert_interval'] || '15.minutes'
            end
          end
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  Transformation::TransformationHost::OVirtHost::TransformVM_vmware2redhat_vddk.new.main
end
