#
# Description: This method is used to find all hosts, datastores that are the least utilized
#
module ManageIQ
  module Automate
    module Infrastructure
      module VM
        module Provisioning
          module Placement
            class VmwareBestFitLeastUtilized
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                @handle.log("info", "vm=[#{vm.name}], space required=[#{vm.provisioned_storage}]")
                best_fit_least_utilized
              end

              private

              def request
                @request ||= @handle.root["miq_provision"].tap do |req|
                  ManageIQ::Automate::System::CommonMethods::Utils::LogObject.log_and_raise('miq_provision not specified', @handle) if req.nil?
                end
              end

              def vm
                @vm ||= request.vm_template.tap do |vm|
                  ManageIQ::Automate::System::CommonMethods::Utils::LogObject.log_and_raise('VM not specified', @handle) if vm.nil?
                end
              end

              def storage_profile_id
                @storage_profile_id ||= request.get_option(:placement_storage_profile).tap do |sp|
                  @handle.log("info", "Selected storage_profile_id: #{sp}") if sp
                end
              end

              def best_fit_least_utilized
                host = storage = min_registered_vms = nil
                request.eligible_hosts.select { |h| !h.maintenance && h.power_state == "on" }.each do |h|
                  next if min_registered_vms && h.vms.size >= min_registered_vms

                  storages = h.writable_storages.find_all { |s| s.free_space > vm.provisioned_storage } # Filter out storages that do not have enough free space for the Vm
                  storages.select! { |s| s.storage_profiles.pluck(:id).include?(storage_profile_id) } if storage_profile_id

                  s = storages.max_by(&:free_space)
                  next if s.nil?
                  host    = h
                  storage = s
                  min_registered_vms = h.vms.size
                end

                # Set host and storage
                request.set_host(host) if host
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

ManageIQ::Automate::Infrastructure::VM::Provisioning::Placement::VmwareBestFitLeastUtilized.new.main
