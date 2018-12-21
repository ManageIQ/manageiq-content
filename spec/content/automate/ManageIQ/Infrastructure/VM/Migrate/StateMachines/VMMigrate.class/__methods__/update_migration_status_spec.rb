require_domain_file

describe ManageIQ::Automate::Infrastructure::VM::Migrate::StateMachines::UpdateMigrationStatus do
  let(:miq_server) { EvmSpecHelper.local_miq_server }
  let(:user) { FactoryBot.create(:user_with_email_and_group) }
  let(:miq_request_task) do
    FactoryBot.create(:miq_request_task, :miq_request => request,
                       :source => vm, :state => 'fred')
  end
  let(:request) { FactoryBot.create(:vm_migrate_request, :requester => user) }
  let(:ems) { FactoryBot.create(:ems_vmware, :zone => FactoryBot.create(:zone)) }
  let(:vm) { FactoryBot.create(:vm_vmware, :ems_id => ems.id, :evm_owner => user) }
  let(:svc_model_miq_server) { MiqAeMethodService::MiqAeServiceMiqServer.find(miq_server.id) }
  let(:root_hash) do
    { 'vm_migrate_task' => MiqAeMethodService::MiqAeServiceMiqRequestTask.find(miq_request_task.id) }
  end

  let(:root_object) do
    obj = Spec::Support::MiqAeMockObject.new(root_hash)
    obj["miq_server"] = svc_model_miq_server
    obj
  end

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  shared_examples_for "#Update Migration Status" do
    it "check" do
      ae_service.root['ae_result'] = ae_result
      allow(ae_service).to receive(:inputs) { {'status' => "ok"} }
      expect(request.reload.message).to eq(msg)
      described_class.new(ae_service).main
    end
  end

  context "returns 'ok' " do
    let(:ae_result) { "ok" }
    let(:msg) { "VM Migrate - Request Created" }
    it_behaves_like "#Update Migration Status"
  end

  context "returns 'error' " do
    it "creates notification due to ae_result is 'error'" do
      ae_service.root['ae_result'] = "error"
      allow(ae_service).to receive(:inputs) { {'status' => "fred"} }
      expect(ae_service).to receive(:create_notification)
      described_class.new(ae_service).main
    end
  end

  context "with no vm" do
    let(:root_hash) { {} }

    it "raises the vm is nil exception" do
      expect { described_class.new(ae_service).main }.to raise_error(
        'ERROR - task object not passed in'
      )
    end
  end
end
