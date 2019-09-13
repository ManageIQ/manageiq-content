require_domain_file

describe ManageIQ::Automate::Infrastructure::VM::Retirement::StateMachines::CheckPoweredOff do
  let(:zone) { FactoryBot.create(:zone) }
  let(:ems) { FactoryBot.create(:ems_microsoft, :zone => zone) }
  let(:vm) do
    FactoryBot.create(:vm_microsoft,
                       :raw_power_state => "PowerOff",
                       :ems_id          => ems.id)
  end

  let(:svc_model_vm) do
    MiqAeMethodService::MiqAeServiceVm.find(vm.id)
  end

  let(:root_hash) do
    { 'vm' => MiqAeMethodService::MiqAeServiceVm.find(vm.id) }
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

  it "returns 'ok' for a vm in powered_off state" do
    described_class.new(ae_service).main
    expect(ae_service.root['vm'].power_state).to eq("off")
    expect(ae_service.root['ae_result']).to eq('ok')
  end

  shared_examples_for "#vm power state" do
    it "check" do
      vm.update(:raw_power_state => raw_power_state)
      svc_model_vm
      described_class.new(ae_service).main
      expect(ae_service.root['vm'].power_state).to eq(power_state)
      expect(ae_service.root['ae_result']).to eq(ae_result)
    end
  end

  context "powered_on " do
    let(:raw_power_state) { "Running" }
    let(:power_state) { "on" }
    let(:ae_result) { "retry" }
    it_behaves_like "#vm power state"
  end
  context "unknown" do
    let(:raw_power_state) { "unknown" }
    let(:power_state) { "unknown" }
    let(:ae_result) { "retry" }
    it_behaves_like "#vm power state"
  end
  context "suspended" do
    let(:raw_power_state) { "suspended" }
    let(:power_state) { "unknown" }
    let(:ae_result) { "retry" }
    it_behaves_like "#vm power state"
  end
  context "never" do
    let(:raw_power_state) { "never" }
    let(:power_state) { "never" }
    let(:ae_result) { "error" }
    it_behaves_like "#vm power state"
  end

  context "exceptions" do
    context "with no ems" do
      let(:vm) do
        FactoryBot.create(:vm_microsoft, :raw_power_state => "PowerOff")
      end

      it "result is nil" do
        expect(ae_service.root['ae_result']).to be_nil
      end
    end

    context "with no vm" do
      let(:root_hash) { {} }
      let(:svc_model_service) { nil }
      let(:vm) { nil }

      it "raises the vm is nil exception" do
        expect { described_class.new(ae_service).main }.to raise_error(
          'ERROR - vm object not passed in'
        )
      end
    end
  end
end
