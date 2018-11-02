###################################################################
#                                                                 #
# Description: Select the cloud network                           #
#              Default availability zone is provided by Openstack #
#                                                                 #
###################################################################
module ManageIQ
  module Automate
    module Cloud
      module VM
        module Provisioning
          module Placement
            class BestFitOpenStack
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                raise "Image not specified" if prov.try(:vm_template).nil?
                set_cloud_network if prov.get_option(:cloud_network).nil?
              end

              private

              def prov
                @prov ||= @handle.root["miq_provision"].tap do |req|
                  raise "miq_provision not provided" unless req
                end
              end

              def set_cloud_network
                cloud_network = prov.eligible_cloud_networks.first

                if cloud_network
                  prov.set_cloud_network(cloud_network)
                  @handle.log("info", "Image=[#{prov.vm_template.name}] Cloud Network=[#{cloud_network.name}]")
                end
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Cloud::VM::Provisioning::Placement::BestFitOpenStack.new.main
