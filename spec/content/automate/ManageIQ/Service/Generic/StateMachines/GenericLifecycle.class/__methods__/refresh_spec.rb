require_domain_file

describe ManageIQ::Automate::Service::Generic::StateMachines::GenericLifecycle::Refresh do
  let(:admin) { FactoryGirl.create(:user_admin) }
  let(:request) { FactoryGirl.create(:service_template_provision_request, :requester => admin) }
  let(:ansible_tower_manager) { FactoryGirl.create(:automation_manager) }
  let(:job_template) { FactoryGirl.create(:ansible_configuration_script, :manager => ansible_tower_manager) }
  let(:service_ansible_tower) { FactoryGirl.create(:service_ansible_tower, :job_template => job_template) }
  let(:task) { FactoryGirl.create(:service_template_provision_task, :destination => service_ansible_tower, :miq_request => request) }
  let(:svc_task) { MiqAeMethodService::MiqAeServiceServiceTemplateProvisionTask.find(task.id) }
  let(:svc_service) { MiqAeMethodService::MiqAeServiceServiceAnsibleTower.find(service_ansible_tower.id) }
  let(:root_object) { Spec::Support::MiqAeMockObject.new('service' => svc_service, 'service_action' => 'Provision') }
  let(:ae_service) { Spec::Support::MiqAeMockService.new(root_object) }
  let(:errormsg) { "simple error" }

  shared_examples_for "refresh_error" do
    it "error" do
      allow(svc_service).to receive(:destination).and_return(svc_service)
      allow(svc_service).to receive(:refresh).and_raise(errormsg)

      expect { described_class.new(ae_service).main }.to raise_error(errormsg)

      expect(ae_service.root['ae_result']).to eq("error")
      expect(ae_service.root['ae_reason']).to eq(errormsg)
    end
  end

  context "invalid service_action" do
    let(:errormsg) { 'Invalid service_action' }
    let(:root_object) do
      Spec::Support::MiqAeMockObject.new('service'        => svc_service,
                                         'service_action' => 'fred')
    end
    it_behaves_like "refresh_error"
  end

  context "task not found" do
    let(:errormsg) { 'service_template_provision_task not found' }
    let(:root_object) do
      Spec::Support::MiqAeMockObject.new('service'        => svc_service,
                                         'service_action' => 'Provision')
    end
    it_behaves_like "refresh_error"
  end

  shared_examples_for "refresh" do
    it "refresh" do
      allow(svc_service).to receive(:destination).and_return(svc_service)
      allow(svc_service).to receive(:refresh).and_return(nil)

      described_class.new(ae_service).main

      expect(ae_service.root['ae_result']).to eq(rc)
      expect(ae_service.root['ae_reason']).to eq(msg)
      expect(svc_task.miq_request[:options][:user_message]).to eq(msg)
    end
  end

  context "service not found" do
    let(:msg) { 'Service not found' }
    let(:rc) { 'error' }
    let(:root_object) do
      Spec::Support::MiqAeMockObject.new('service_template_provision_task' => task,
                                         'service_action'                  => 'Provision')
    end
    it_behaves_like "refresh"
  end

  context "refresh" do
    it "successful scenario" do
      allow(svc_task).to receive(:destination).and_return(svc_service)
      allow(svc_service).to receive(:refresh).and_return(nil)

      described_class.new(ae_service).main

      expect(ae_service.root['ae_result']).to eq("ok")
    end
  end
end
