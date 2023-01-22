#
# Description: This method is used to deploy physical server from server profile template
#

module ManageIQ
  module Automate
    module PhysicalInfrastructure
      module CiscoIntersight
        module Services
          module DeployServer
            module Methods
              class DeployServerProfileTemplate
                def initialize(handle = $evm)
                  @handle = handle
                end

                def main
                  log(:info, "Service template provision task id:<#{service_template_provision_task.id}> ")
                  log(:info, "Server Profile Template id: #{template_id}")
                  log(:info, "Deploying server from server profile template...", true)
                  process_deployment
                  log(:info, "Deploy server from server profile template...Complete", true)
                end

                def service_template_provision_task
                  @handle.root['service_template_provision_task']
                end

                def template_id
                  service_template_object = service_template_provision_task.source
                  template_id = service_template_object.options[:server_profile_template_id]
                  if template_id.blank?
                    template_id = @handle.root.attributes['dialog_template']
                  end
                  raise 'server profile template not specified' if template_id.blank?

                  template_id
                end

                def process_deployment
                  set_options
                  deploy_from_options
                end

                def set_options
                  @profile_name = @handle.root.attributes['dialog_name']
                  @server_id = @handle.root.attributes['dialog_server']
                end

                def deploy_from_options
                  manager = @handle.vmdb(:physical_server)
                  manager.create_server_profile_and_deploy_task(template_id, @server_id, @profile_name)
                end

                def log(level, msg, update_message: false)
                  @handle.log(level, msg)
                  @handle.root['miq_provision'].message = msg if @handle.root['miq_provision'] && update_message
                end
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::PhysicalInfrastructure::CiscoIntersight::Services::DeployServer::Methods::DeployServerProfileTemplate.new.main
