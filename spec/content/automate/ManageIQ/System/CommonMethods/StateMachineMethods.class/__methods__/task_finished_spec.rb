require_domain_file

describe ManageIQ::Automate::System::CommonMethods::StateMachineMethods::TaskFinished do
  include Spec::Support::AutomationHelper

  let(:user) { FactoryBot.create(:user_with_group) }
  let(:miq_server) { EvmSpecHelper.local_miq_server }

  let(:method_args) do
    { 'message' => 'finished message here' }
  end

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_hash).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      service.object = current_object
      service.inputs = method_args
    end
  end

  context "service_template_provision_task" do
    let(:svc_service_template_provision_task) { MiqAeMethodService::MiqAeServiceMiqRequestTask.find(service_template_provision_task.id) }
    let(:vmdb_object_type) { 'service_template_provision_task' }
    let(:service) { FactoryBot.create(:service) }
    let(:service_template_provision_request) do
      FactoryBot.create(:service_template_provision_request,
                        :requester => user)
    end

    let(:service_template_provision_task) do
      FactoryBot.create(:service_template_provision_task,
                        :miq_request => service_template_provision_request,
                        :destination => service)
    end

    let(:root_hash) do
      {
        'service_template_provision_task' => svc_service_template_provision_task,
        'vmdb_object_type'                => vmdb_object_type,
        'miq_server'                      => miq_server
      }
    end

    it "task_finished" do
      expect(ae_service).to receive(:create_notification).once
      allow(svc_service_template_provision_task).to receive(:finished).once
      expect(Notification.count).to eq(0)

      described_class.new(ae_service).main

      expect(ae_service.root['vmdb_object_type']).to eq(vmdb_object_type)
      expect(service_template_provision_request.status).to eq('Ok')
    end
  end

  context "miq_provision_task" do
    let(:ems) { FactoryBot.create(:ems_vmware_with_authentication) }
    let(:vm_template) { FactoryBot.create(:template_vmware, :ext_management_system => ems) }
    let(:vm) { FactoryBot.create(:vm_vmware, :ext_management_system => ems) }
    let(:options) { {:src_vm_id => [vm_template.id, vm_template.name], :pass => 1} }
    let(:svc_miq_provision_task) { MiqAeMethodService::MiqAeServiceMiqRequestTask.find(prov_task.id) }
    let(:vmdb_object_type) { 'miq_provision' }

    let(:miq_provision_request) do
      FactoryBot.create(:miq_provision_request,
                        :provision_type => 'template',
                        :state          => 'pending',
                        :status         => 'Ok',
                        :src_vm_id      => vm_template.id,
                        :requester      => user)
    end

    let(:prov_task) do
      FactoryBot.create(:miq_provision_vmware,
                        :provision_type => 'template',
                        :state          => 'pending',
                        :status         => 'Ok',
                        :miq_request    => miq_provision_request,
                        :options        => options,
                        :userid         => user.userid,
                        :vm             => vm)
    end

    let(:root_hash) do
      {
        'miq_provision'    => svc_miq_provision_task,
        'vmdb_object_type' => vmdb_object_type,
        'miq_server'       => miq_server
      }
    end

    it "task_finished" do
      expect(ae_service).to receive(:create_notification)
      allow(svc_miq_provision_task).to receive(:get_option).with(:request_type).and_return('clone_to_vm')
      allow(svc_miq_provision_task).to receive(:get_option).with(:vm_target_name).and_return('fred')
      allow(svc_miq_provision_task).to receive(:finished).once
      expect(Notification.count).to eq(0)

      described_class.new(ae_service).main

      expect(ae_service.root['vmdb_object_type']).to eq(vmdb_object_type)
    end
  end

  context "vm_retirement_task" do
    let(:ems) { FactoryBot.create(:ems_vmware_with_authentication) }
    let(:vm) { FactoryBot.create(:vm_vmware, :ext_management_system => ems) }
    let(:svc_vm_retire_task) { MiqAeMethodService::MiqAeServiceMiqRequestTask.find(prov_task.id) }
    let(:vmdb_object_type) { 'vm_retire_task' }

    let(:root_hash) do
      {
        'vm_retire_task'   => svc_vm_retire_task,
        'vmdb_object_type' => vmdb_object_type,
        'miq_server'       => miq_server
      }
    end

    let(:miq_provision_request) do
      FactoryBot.create(:vm_retire_request,
                        :requester => user)
    end

    let(:prov_task) do
      FactoryBot.create(:miq_request_task,
                        :miq_request => miq_provision_request,
                        :state       => 'fred')
    end

    it "task_finished" do
      allow(vm).to receive(:finish_retirement)
      allow(svc_vm_retire_task).to receive(:get_option).with(:vm_target_name).and_return('fred')
      allow(svc_vm_retire_task).to receive(:finished).once

      described_class.new(ae_service).main

      msg = "[#{miq_server.name}] finished message here"
      expect(miq_provision_request.reload.message).to eq(msg)
    end
  end
end
