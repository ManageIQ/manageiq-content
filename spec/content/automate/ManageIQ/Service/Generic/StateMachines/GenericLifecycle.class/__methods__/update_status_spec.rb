require_domain_file

describe ManageIQ::Automate::Service::Generic::StateMachines::GenericLifecycle::UpdateStatus do
  let(:admin) { FactoryGirl.create(:user_admin) }
  let(:request) { FactoryGirl.create(:service_template_provision_request, :requester => admin) }
  let(:ansible_tower_manager) { FactoryGirl.create(:automation_manager) }
  let(:job_template) { FactoryGirl.create(:ansible_configuration_script, :manager => ansible_tower_manager) }
  let(:service_ansible_tower) { FactoryGirl.create(:service_ansible_tower, :job_template => job_template) }
  let(:task) { FactoryGirl.create(:service_template_provision_task, :destination => service_ansible_tower, :miq_request => request) }
  let(:svc_task) { MiqAeMethodService::MiqAeServiceServiceTemplateProvisionTask.find(task.id) }
  let(:svc_service) { MiqAeMethodService::MiqAeServiceServiceAnsibleTower.find(service_ansible_tower.id) }
  let(:root_object) do
    Spec::Support::MiqAeMockObject.new('service'        => svc_service,
                                       'service_action' => 'Provision',
                                       'miq_server'     => svc_model_miq_server)
  end
  let(:ae_service) { Spec::Support::MiqAeMockService.new(root_object) }
  let(:errormsg) { "simple error" }
  let(:svc_model_request) { MiqAeMethodService::MiqAeServiceServiceTemplateProvisionRequest.find(request.id) }
  let(:miq_server) { EvmSpecHelper.local_miq_server }
  let(:svc_model_miq_server) { MiqAeMethodService::MiqAeServiceMiqServer.find(miq_server.id) }

  shared_examples_for "update_status_error" do
    it "error" do
      allow(svc_service).to receive(:destination).and_return(svc_service)
      allow(ae_service).to receive(:inputs) { {'status' => "fred"} }

      expect { described_class.new(ae_service).main }.to raise_error(errormsg)
    end
  end

  context "invalid service_action" do
    let(:errormsg) { 'Invalid service_action' }
    let(:root_object) do
      Spec::Support::MiqAeMockObject.new('service'        => svc_service,
                                         'service_action' => 'fred',
                                         'miq_server'     => svc_model_miq_server)
    end
    it_behaves_like "update_status_error"
  end

  context "task not found" do
    let(:errormsg) { 'service_template_provision_task not found' }
    let(:root_object) do
      Spec::Support::MiqAeMockObject.new('service'        => svc_service,
                                         'service_action' => 'Provision',
                                         'miq_server'     => svc_model_miq_server)
    end
    it_behaves_like "update_status_error"
  end

  context "service not found" do
    let(:errormsg) { 'Service not found' }
    let(:root_object) do
      Spec::Support::MiqAeMockObject.new('service_template_provision_task' => task,
                                         'service_action'                  => 'Provision',
                                         'miq_server'                      => svc_model_miq_server)
    end
    it_behaves_like "update_status_error"
  end

  context "update_status" do
    let(:root_object) do
      Spec::Support::MiqAeMockObject.new('service_template_provision_task' => task,
                                         'service_action'                  => 'Provision',
                                         'service'                         => svc_service,
                                         'miq_server'                      => svc_model_miq_server)
    end
    it "successful scenario" do
      allow(svc_task).to receive(:destination).and_return(svc_service)
      allow(svc_service).to receive(:update_status).and_return(nil)
      allow(ae_service).to receive(:inputs) { {'status' => "fred"} }

      described_class.new(ae_service).main

      msg = "Server [#{miq_server.name}] Service [#{svc_service.name}] Step [] Status [fred] "
      expect(svc_model_request.reload.message).to eq(msg)
    end
  end
end
