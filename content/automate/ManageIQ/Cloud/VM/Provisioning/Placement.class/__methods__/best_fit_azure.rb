###################################################################
#                                                                 #
# Description: Select the cloud network, availability zone        #
#              and resource group for Azure                       #
#                                                                 #
###################################################################
module ManageIQ
  module Automate
    module Cloud
      module VM
        module Provisioning
          module Placement
            class BestFitAzure
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                @handle.log("info", "Using Auto Placement for Azure Cloud Provider")
                raise "Image not specified" if prov.try(:vm_template).nil?

                prov.get_option(:cloud_network)  || default_cloud_network
                prov.get_option(:cloud_subnet)   || default_cloud_subnet
                prov.get_option(:resource_group) || default_resource_group
              end

              private

              def prov
                @prov ||= @handle.root["miq_provision"].tap do |req|
                  raise "miq_provision not provided" unless req
                end
              end

              def default_cloud_network
                cloud_network = prov.eligible_cloud_networks.first

                if cloud_network
                  prov.set_cloud_network(cloud_network)
                  @handle.log("info", "Selected Cloud Network: #{cloud_network.name}")
                end
              end

              def default_cloud_subnet
                cloud_subnet = prov.eligible_cloud_subnets.first
                raise "No cloud subnets found for cloud network" unless cloud_subnet

                prov.set_cloud_subnet(cloud_subnet)
                @handle.log("info", "Selected Cloud Subnet: #{cloud_subnet.name}")
              end

              def default_resource_group
                resource_group = prov.eligible_resource_groups.first

                if resource_group
                  prov.set_resource_group(resource_group)
                  @handle.log("info", "Selected Resource Group: #{resource_group.name}")
                end
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Cloud::VM::Provisioning::Placement::BestFitAzure.new.main
