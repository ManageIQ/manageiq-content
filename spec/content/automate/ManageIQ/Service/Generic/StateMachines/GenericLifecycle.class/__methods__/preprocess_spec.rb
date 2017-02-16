require_domain_file

describe ManageIQ::Automate::Service::Generic::StateMachines::GenericLifecycle::PreProcess do
  let(:admin) { FactoryGirl.create(:user_admin) }
  let(:request) { FactoryGirl.create(:service_template_provision_request, :requester => admin) }
  let(:ansible_tower_manager) { FactoryGirl.create(:configuration_manager) }
  let(:job_template) { FactoryGirl.create(:ansible_configuration_script, :manager => ansible_tower_manager) }
  let(:service_ansible_tower) { FactoryGirl.create(:service_ansible_tower, :job_template => job_template) }
  let(:task) { FactoryGirl.create(:service_template_provision_task, :destination => service_ansible_tower, :miq_request => request) }
  let(:svc_task) { MiqAeMethodService::MiqAeServiceServiceTemplateProvisionTask.find(task.id) }
  let(:svc_service) { MiqAeMethodService::MiqAeServiceServiceAnsibleTower.find(service_ansible_tower.id) }
  let(:root_object) { Spec::Support::MiqAeMockObject.new('service_template_provision_task' => svc_task, 'service_action' => 'Provision') }
  let(:ae_service) { Spec::Support::MiqAeMockService.new(root_object) }
  let(:errormsg) { "error" }

  context "PreProcess" do
    it "failed scenario" do
      allow(svc_task).to receive(:destination).and_return(svc_service)
      allow(svc_service).to receive(:preprocess).and_raise(errormsg)

      described_class.new(ae_service).main

      expect(ae_service.root['ae_result']).to eq("error")
      expect(ae_service.root['ae_reason']).to eq(errormsg)
      expect(svc_task.miq_request[:options][:user_message]).to eq(errormsg)
    end
  end

  shared_examples_for "preprocess_error" do
    it "preprocess_error" do
      allow(svc_task).to receive(:destination).and_return(svc_service)
      allow(svc_service).to receive(:preprocess).and_return(nil)
      root_object['service_action'] = service_action

      described_class.new(ae_service).main

      expect(ae_service.root['ae_result']).to eq(ae_result)
      expect(ae_service.root['ae_reason']).to eq(errormsg)
      expect(svc_task.miq_request[:options][:user_message]).to eq(errormsg)
    end
  end

  shared_examples_for "preprocess" do
    it "preprocess" do
      allow(svc_task).to receive(:destination).and_return(svc_service)
      allow(svc_service).to receive(:preprocess).and_return(nil)

      described_class.new(ae_service).main

      expect(ae_service.root['ae_result']).to eq(ae_result)
    end
  end

  context "successful scenario" do
    let(:ae_result) { 'ok' }
    it_behaves_like "preprocess"
  end

  context "invalid service_action failure" do
    let(:service_action) { 'fred' }
    let(:ae_result) { 'error' }
    let(:errormsg) { 'Invalid service_action' }
    it_behaves_like "preprocess_error"
  end
end
