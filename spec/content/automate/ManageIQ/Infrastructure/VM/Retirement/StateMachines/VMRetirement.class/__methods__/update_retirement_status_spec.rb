require_domain_file

describe ManageIQ::Automate::Infrastructure::VM::Retirement::StateMachines::VMRetirement::UpdateRetirementStatus do
  let(:user) { FactoryGirl.create(:user_with_group) }
  let(:miq_server) { EvmSpecHelper.local_miq_server }
  let(:vm) { FactoryGirl.create(:vm_vmware, :ems_id => FactoryGirl.create(:ems_vmware).id, :evm_owner => user) }
  let(:root_hash) do
    { }
  end
  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  let(:svc_model_miq_server) { MiqAeMethodService::MiqAeServiceMiqServer.find(miq_server.id) }
  let(:svc_model_vm) { MiqAeMethodService::MiqAeServiceVm.find(vm.id) }

  context "with a stp request object" do
    let(:miq_request_task) do
      FactoryGirl.create(:miq_request_task,
                         :miq_request => request, :state => 'fred')
    end
    let(:request) do
      FactoryGirl.create(:vm_retire_request, :requester => user)
    end
    let(:svc_model_miq_request_task) { MiqAeMethodService::MiqAeServiceMiqRequestTask.find(miq_request_task.id) }
    let(:svc_model_request) do
      MiqAeMethodService::MiqAeServiceVmRetireRequest.find(request.id)
    end

    let(:root_object) do
      obj = Spec::Support::MiqAeMockObject.new(root_hash)
      obj["vm_retire_task"] = svc_model_miq_request_task
      obj["miq_server"] = svc_model_miq_server
      obj["vm"] = svc_model_vm
      obj
    end

    before do
      allow(ae_service).to receive(:inputs) { {'status' => "fred"} }
      ae_service.root['ae_result'] = 'ok'
      ae_service.root['ae_status'] = 'ok'
    end

    it "method succeeds" do
      described_class.new(ae_service).main
      expect(svc_model_request.reload.status).to eq('Ok')
    end

    it "request message set properly" do
      described_class.new(ae_service).main
      msg = "Server [#{miq_server.name}] Step [] Status [fred] "
      expect(svc_model_request.reload.message).to eq(msg)
    end

    it "creates notification due to ae_result is 'error'" do
      ae_service.root['ae_result'] = "error"
      ae_service.root['ae_state'] = "thingotherthanstartretirement"
      expect(ae_service).to receive(:create_notification)
      described_class.new(ae_service).main
      expect(svc_model_vm.retirement_state).to eq('error')
    end

    it "creates notification due to ae_result is 'error'" do
      ae_service.root['ae_result'] = "error"
      ae_service.root['ae_state'] = "startretirement"
      expect(ae_service).to receive(:create_notification)
      described_class.new(ae_service).main
    end
  end

  context "without a stp request object" do
    let(:root_object) do
      obj = Spec::Support::MiqAeMockObject.new(root_hash)
      obj["miq_server"] = svc_model_miq_server
      obj["vm"] = svc_model_vm
      obj
    end

    before do
      allow(ae_service).to receive(:inputs) { {'status' => "fred"} }
      ae_service.root['ae_result'] = 'ok'
      ae_service.root['ae_status'] = 'ok'
    end

    it "creates notification due to ae_result is 'error'" do
      ae_service.root['ae_result'] = "error"
      ae_service.root['ae_state'] = "thingotherthanstartretirement"
      expect(ae_service).to receive(:create_notification)
      described_class.new(ae_service).main
      expect(svc_model_vm.retirement_state).to eq('error')
    end

    it "creates notification due to ae_result is 'error'" do
      ae_service.root['ae_result'] = "error"
      ae_service.root['ae_state'] = "startretirement"
      expect(ae_service).to receive(:create_notification)
      described_class.new(ae_service).main
    end
  end
end
