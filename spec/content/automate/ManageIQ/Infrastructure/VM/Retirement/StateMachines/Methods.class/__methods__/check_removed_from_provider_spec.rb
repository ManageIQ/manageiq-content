require_domain_file

describe ManageIQ::Automate::Infrastructure::VM::Retirement::StateMachines::CheckRemovedFromProvider do
  let(:ems)  { FactoryGirl.create(:ems_vmware, :zone => FactoryGirl.create(:zone)) }
  let(:vm) { FactoryGirl.create(:vm_vmware, :ems_id => ems.id) }
  let(:svc_model_vm) do
    MiqAeMethodService::MiqAeServiceVm.find(vm.id)
  end

  let(:root_hash) do
    {'vm' => svc_model_vm }
  end

  let(:root_object) do
    Spec::Support::MiqAeMockObject.new(root_hash)
  end

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  it "returns 'retry' if vm, ems and state var true" do
    ae_service.set_state_var('vm_removed_from_provider', true)
    expect(svc_model_vm).to receive(:refresh)
    described_class.new(ae_service).main
    expect(ae_service.root['ae_result']).to eq('retry')
  end

  shared_examples_for "#state var" do
    it "check" do
      ae_service.set_state_var('vm_removed_from_provider', removed_from_provider)
      described_class.new(ae_service).main
      expect(ae_service.root['ae_result']).to eq(ae_result)
    end
  end

  context "returns 'ok' if ems and state var false" do
    let(:ae_result) { "ok" }
    let(:removed_from_provider) { false }
    it_behaves_like "#state var"
  end

  context "returns 'ok' if no ems and state var false" do
    let(:vm) { FactoryGirl.create(:vm_vmware) }
    let(:ae_result) { "ok" }
    let(:removed_from_provider) { false }
    it_behaves_like "#state var"
  end

  context "returns 'ok' if state var true" do
    let(:vm) { FactoryGirl.create(:vm_vmware) }
    let(:ae_result) { "ok" }
    let(:removed_from_provider) { true }
    it_behaves_like "#state var"
  end

  context "with no vm" do
    let(:root_hash) { {} }

    it "raises the vm is nil exception" do
      expect { described_class.new(ae_service).main }.to raise_error(
        'ERROR - vm object not passed in'
      )
    end
  end
end
