require_domain_file

describe ManageIQ::Automate::Infrastructure::VM::Migrate::StateMachines::Checkmigration do
  let(:miq_server) { EvmSpecHelper.local_miq_server }
  let(:user) { FactoryBot.create(:user_with_email_and_group) }
  let(:miq_request_task) { FactoryBot.create(:vm_migrate_task, :miq_request => request, :source => vm, :message => 'active') }
  let(:request) { FactoryBot.create(:vm_migrate_request, :requester => user) }
  let(:ems) { FactoryBot.create(:ems_vmware, :zone => FactoryBot.create(:zone)) }
  let(:vm) { FactoryBot.create(:vm_vmware, :ems_id => ems.id) }
  let(:root_hash) do
    { 'vm_migrate_task' => MiqAeMethodService::MiqAeServiceMiqRequestTask.find(miq_request_task.id) }
  end

  let(:root_object) do
    obj = Spec::Support::MiqAeMockObject.new(root_hash)
    obj["miq_server"] = "MiqAeMethodService::MiqAeServiceMiqServer.find(miq_server.id)"
    obj
  end

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  context "checks for state and status" do
    let(:interval) { nil }

    shared_examples_for "#task_status" do
      it "checks for return_status and interval" do
        miq_request_task.update_attributes(:state => state, :status => status)
        allow(ae_service).to receive(:inputs) { {'state' => state} }
        described_class.new(ae_service).main
        expect(ae_service.root['ae_result']).to eq(return_status)
        expect(ae_service.root['ae_retry_interval']).to eq(interval)
      end
    end

    context "returns 'ok' if state finished and status Ok" do
      let(:return_status) { "ok" }
      let(:state) { "finished" }
      let(:status) { "Ok" }

      it_behaves_like "#task_status"
    end

    context "returns 'ok' if state migrated and status Ok" do
      let(:return_status) { "ok" }
      let(:state) { "migrated" }
      let(:status) { "Ok" }

      it_behaves_like "#task_status"
    end

    context "returns 'retry' if state pending and status Ok" do
      let(:return_status) { "retry" }
      let(:state) { "pending" }
      let(:status) { "Ok" }
      let(:interval) { 1.minute }

      it_behaves_like "#task_status"
    end

    context "returns 'retry' if state pending and status Error" do
      let(:return_status) { "retry" }
      let(:state) { "pending" }
      let(:status) { "Error" }
      let(:interval) { 1.minute }

      it_behaves_like "#task_status"
    end

    context "returns 'error' if state finished and status Error" do
      let(:return_status) { "error" }
      let(:state) { "finished" }
      let(:status) { "Error" }

      it_behaves_like "#task_status"
    end

    context "returns 'error' if state migrated and status Error" do
      let(:return_status) { "error" }
      let(:state) { "migrated" }
      let(:status) { "Error" }

      it_behaves_like "#task_status"
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
