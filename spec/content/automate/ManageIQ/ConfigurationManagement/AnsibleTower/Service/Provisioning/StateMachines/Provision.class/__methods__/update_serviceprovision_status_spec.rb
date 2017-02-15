require_domain_file

describe ManageIQ::Automate::ConfigurationManagement::AnsibleTower::Service::
          Provisioning::StateMachines::UpdateServiceProvisionStatus do
  let(:user)                  { FactoryGirl.create(:user_with_group) }
  let(:miq_server)            { EvmSpecHelper.local_miq_server }
  let(:service_orchestration) { FactoryGirl.create(:service_orchestration) }

  let(:miq_request_task) do
    FactoryGirl.create(:miq_request_task, :destination => service_orchestration,
                       :miq_request => request, :state => 'fred')
  end

  let(:request) do
    FactoryGirl.create(:service_template_provision_request, :requester => user)
  end

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  let(:svc_model_miq_server)       { MiqAeMethodService::MiqAeServiceMiqServer.find(miq_server.id) }
  let(:svc_model_miq_request_task) { MiqAeMethodService::MiqAeServiceMiqRequestTask.find(miq_request_task.id) }
  let(:svc_model_service)          { MiqAeMethodService::MiqAeServiceService.find(service_orchestration.id) }
  let(:svc_model_request) do
    MiqAeMethodService::MiqAeServiceServiceTemplateProvisionRequest.find(request.id)
  end

  context "with a stp request object" do
    let(:root_hash) do
      { 'service_template' => MiqAeMethodService::MiqAeServiceService.find(service_orchestration.id) }
    end

    let(:root_object) do
      obj = Spec::Support::MiqAeMockObject.new(root_hash)
      obj["service_template_provision_task"] = svc_model_miq_request_task
      obj["miq_server"] = svc_model_miq_server
      obj
    end

    before do
      allow(ae_service).to receive(:inputs) { {'status' => "fred"} }
      allow(svc_model_miq_request_task).to receive(:destination) { svc_model_service }
      ae_service.root['ae_result'] = 'ok'
    end

    it "method succeeds" do
      described_class.new(ae_service).main
      expect(svc_model_request.reload.status).to eq('Ok')
    end

    it "request message set properly" do
      described_class.new(ae_service).main
      msg = "Server [#{miq_server.name}] Service [#{service_orchestration.name}] Step [] Status [fred] Message [] "
      expect(svc_model_request.reload.message).to eq(msg)
    end
  end

  context "without a stp request object" do
    let(:root_hash)   { {} }
    let(:root_object) { Spec::Support::MiqAeMockObject.new(root_hash) }

    it "method fails" do
      expect { described_class.new(ae_service).main }.to raise_error(
        "Service Template Provision Task not provided"
      )
    end
  end
end
