#
# Description: This method is used to find all hosts, datastores that are the least utilized
#
module ManageIQ
  module Automate
    module Infrastructure
      module VM
        module Provisioning
          module Placement
            class MicrosoftBestFitLeastUtilized
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                @handle.log("info", "vm=[#{vm.name}], space required=[#{vm.provisioned_storage}]")
                best_fit_least_utilized
              end

              private

              def request
                @handle.root["miq_provision"].tap do |req|
                  raise 'miq_provision not specified' if req.nil?
                end
              end

              def vm
                request.vm_template.tap do |vm|
                  raise 'VM not specified' if vm.nil?
                  raise "EMS not found for VM [#{vm.name}]" if vm.ext_management_system.nil?
                end
              end

              def clear_host
                request.set_option(:placement_host_name, [nil, nil])
              end

              def best_fit_least_utilized
                host = storage = min_registered_vms = nil
                request.eligible_hosts.select { |h| !h.maintenance && h.power_state == "on" }.each do |h|
                  next if min_registered_vms && h.vms.size >= min_registered_vms

                  # Setting the host to filter eligible storages
                  request.set_host(h)

                  # Filter out storages that do not have enough free space for the Vm
                  storages = request.eligible_storages.find_all { |s| s.free_space > vm.provisioned_storage }

                  s = storages.max_by(&:free_space)
                  next if s.nil?

                  host = h
                  storage = s
                  min_registered_vms = h.vms.size
                end

                # Set host and storage
                host ? request.set_host(host) : clear_host
                request.set_storage(storage) if storage

                @handle.log("info", "vm=[#{vm.name}] host=[#{host}] storage=[#{storage}]")
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Infrastructure::VM::Provisioning::Placement::MicrosoftBestFitLeastUtilized.new.main
