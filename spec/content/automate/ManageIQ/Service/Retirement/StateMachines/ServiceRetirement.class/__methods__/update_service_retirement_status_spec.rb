require_domain_file

describe ManageIQ::Automate::Service::Retirement::StateMachines::
ServiceRetirement::UpdateServiceRetirementStatus do
  let(:user)                  { FactoryBot.create(:user_with_group) }
  let(:miq_server)            { EvmSpecHelper.local_miq_server }
  let(:miq_request_task) do
    FactoryBot.create(:miq_request_task,
                      :miq_request => request,
                      :state       => 'active')
  end

  let(:request) do
    FactoryBot.create(:service_retire_request, :requester => user)
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
  let(:svc_model_request) do
    MiqAeMethodService::MiqAeServiceServiceRetireRequest.find(request.id)
  end

  context "with a stp request object" do
    let(:root_hash) do
      { }
    end

    let(:root_object) do
      obj = Spec::Support::MiqAeMockObject.new(root_hash)
      obj["service_retire_task"] = svc_model_miq_request_task
      obj["miq_server"] = svc_model_miq_server
      obj
    end

    before do
      allow(ae_service).to receive(:inputs) { {'status' => "active"} }
      ae_service.root['ae_result'] = 'ok'
    end

    it "method succeeds" do
      described_class.new(ae_service).main
      expect(svc_model_request.reload.status).to eq('Ok')
    end

    it "request message set properly" do
      described_class.new(ae_service).main
      msg = "Server [#{miq_server.name}] Step [] Status [active] Message [] "
      expect(svc_model_request.reload.message).to eq(msg)
    end

    it "creates notification due to ae_result is 'error'" do
      ae_service.root['ae_result'] = "error"
      expect(ae_service).to receive(:create_notification)
      described_class.new(ae_service).main
    end
  end

  context "without a service retire task" do
    let(:root_hash)   { {} }
    let(:root_object) do
      obj = Spec::Support::MiqAeMockObject.new(root_hash)
      obj["miq_server"] = svc_model_miq_server
      obj
    end

    it "Task not provided" do
      described_class.new(ae_service).main
      expect { described_class.new(ae_service).main }.not_to raise_error
    end
  end
end
