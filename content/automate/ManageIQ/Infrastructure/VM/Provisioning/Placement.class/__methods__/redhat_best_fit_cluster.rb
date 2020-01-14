#
# Description: This method sets the cluster based on source template
#
module ManageIQ
  module Automate
    module Infrastructure
      module VM
        module Provisioning
          module Placement
            class RedhatBestFitCluster
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                best_fit_cluster
              end

              private

              def request
                @handle.root["miq_provision"].tap do |req|
                  raise "miq_provision not specified" if req.nil?
                end
              end

              def vm
                request.vm_template.tap do |vm|
                  raise 'VM not specified' if vm.nil?
                  raise "EMS not found for VM [#{vm.name}]" if vm.ext_management_system.nil?
                end
              end

              def best_fit_cluster
                @handle.log("info", "vm=[#{vm.name}]")

                cluster = vm.ems_cluster
                @handle.log("info", "Selected Cluster: [#{cluster.nil? ? "nil" : cluster.name}]")

                # Set cluster
                request.set_cluster(cluster) if cluster

                @handle.log("info", "vm=[#{vm.name}] cluster=[#{cluster}]")
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Infrastructure::VM::Provisioning::Placement::RedhatBestFitCluster.new.main
