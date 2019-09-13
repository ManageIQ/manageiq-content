require_domain_file

describe ManageIQ::Automate::Cloud::VM::Retirement::StateMachines::Methods::PreRetirement do
  let(:svc_vm)      { MiqAeMethodService::MiqAeServiceVm.find(vm.id) }
  let(:ems)         { FactoryBot.create(:ems_microsoft) }
  let(:root_object) { Spec::Support::MiqAeMockObject.new(root_hash) }
  let(:root_hash)   { { 'vm' => svc_vm } }
  let(:vm) do
    FactoryBot.create(:vm_microsoft, :ems_id => ems.id)
  end

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  it 'powers off a vm in a \'powered_on\' state' do
    expect(svc_vm).to receive(:stop)
    described_class.new(ae_service).main
  end

  it 'does not stop a vm in \'powered_off\' state' do
    vm.update(:raw_power_state => "PowerOff")
    expect(svc_vm).to_not receive(:stop)
    described_class.new(ae_service).main
  end

  context 'nil ems' do
    let(:vm) { FactoryBot.create(:vm_microsoft) }

    it 'does not stop a vm without ems' do
      expect(svc_vm).to_not receive(:stop)
      described_class.new(ae_service).main
    end
  end
end
