#
# Description: Add a VM to a Service
# Input: job_id        The ID of the Job
#        vm_name       The VM Name
#
#
module ManageIQ
  module Automate
    module System
      module Request
        class AddVmToService

          def initialize(handle = $evm)
              @handle = handle
          end

          def main
            vm.add_to_service(service)
          end

          private 

          def job
            # Lookup for Service associated with ansible tower job_id
            job_id = @handle.object['job_id']
            job = @handle.vmdb('orchestration_stack').find_by_ems_ref(job_id)
            if job.nil?
              @handle.log("error", "Can't find Ansible Job with ems_ref: #{job_id}")
              raise "Can't find Ansible Job with ems_ref; #{job_id}"
            end
            @handle.log("info", "Found Ansible Job with id: #{job.id} and name: #{job.name}")
            return job
          end

          def service
            # Lookup for Service from Ansible Job (Orchestration Stack)
            resource = @handle.vmdb('service_resource').find_by_resource_id(job.id)
            if resource.nil?
              @handle.log("error", "Can't find Service resource with resource_id: #{job.id}")
              raise "Can't find Service resource with resource_id: #{job.id}"
            end
            @handle.log("info", "Found Service Resource with id: #{resource.id}")

            # Lookup for service from Resource
            service = @handle.vmdb('service').find_by_id(resource.service_id)
            if service.nil?
              @handle.log("error", "Can't find Service with id: #{resource.service_id}")
              raise "Can't find Service with id: #{resource.service_id}"
            end
            @handle.log("info", "Found Service with id: #{resource.service_id} and name: #{service.name}")
            return service
          end

          def vm
            # Lookup for VM with vm_name
            vm_name = @handle.object['vm_name']
            vm = @handle.vmdb('vm').find_by_name(vm_name)
            if vm.nil?
              @handle.log("error", "Can't find VM with name: #{vm_name}")
              raise "Can't find VM with name: #{vm_name}"
            end
            @handle.log("info", "Found VM with id: #{vm.id} and name: #{vm.name}")
            return vm
          end
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  ManageIQ::Automate::System::Request::AddVmToService.new.main
end
