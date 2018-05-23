module ManageIQ
  module Automate
    module Transformation
      module TransformationHosts
        module OVirtHost
          class Utils        
            def initialize(handle = $evm)
              @handle = handle
            end
   
            def self.remote_command(host, command, stdin=nil, run_as=nil)
              require "net/ssh"
              command = "sudo -u #{run_as} #{command}" unless run_as.nil?
              success, stdout, stderr, exit_code = true, '', '', nil
              Net::SSH.start(host.name, host.authentication_userid, :password => host.authentication_password) do |ssh|
                channel = ssh.open_channel do |channel|
                  channel.request_pty unless run_as.nil?
                  channel.exec(command) do |channel, success|
                    if success
                      channel.on_data do |_, data|
                        stdout += data.to_s
                      end
                      channel.on_extended_data do |_, data|
                        stderr += data.to_s
                      end
                      channel.on_request("exit-status") do |ch,data|
                        exit_code = data.read_long
                      end
                      unless stdin.nil?
                        channel.send_data(stdin)
                        channel.eof!
                      end
                    else
                      success = false
                      stderr = "Could not execute command."
                    end
                  end
                end
                channel.wait
              end
              return { :success => success, :stdout => stdout, :stderr => stderr, :rc => exit_code }
            end
            
            def self.ansible_playbook(host, playbook, extra_vars)
              require "net/ssh"
              command = "ansible-playbook -i #{host.name}, #{playbook}"
              extra_vars.each { |k,v| command += " -e '#{k}=#{v}'" }
              success, stdout, stderr, exit_code = true, '', '', nil
              Net::SSH.start(host.ext_management_system.hostname, 'root') do |ssh|
                  channel = ssh.open_channel do |channel|
                  channel.exec(command) do |channel, success|
                    if success
                      channel.on_data do |_, data|
                        stdout += data.to_s
                      end
                      channel.on_extended_data do |_, data|
                        stderr += data.to_s
                      end
                      channel.on_request("exit-status") do |ch,data|
                        exit_code = data.read_long
                      end
                    else
                      success = false
                      stderr = "Could not execute command."
                    end
                  end
                end
                channel.wait
              end
              return { :success => success, :stdout => stdout, :stderr => stderr, :rc => exit_code }
            end
          end
        end
      end
    end
  end
end
