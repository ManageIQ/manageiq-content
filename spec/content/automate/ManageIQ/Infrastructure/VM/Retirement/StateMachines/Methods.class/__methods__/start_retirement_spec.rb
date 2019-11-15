require_domain_file

describe ManageIQ::Automate::Infrastructure::VM::Retirement::StateMachines::Methods::StartRetirement do
  let(:svc_vm)      { MiqAeMethodService::MiqAeServiceVm.find(vm.id) }
  let(:ems)         { FactoryBot.create(:ems_vmware) }
  let(:vm)          { FactoryBot.create(:vm_vmware, :ems_id => ems.id) }
  let(:root_object) { Spec::Support::MiqAeMockObject.new(root_hash) }
  let(:root_hash)   { { 'vm' => svc_vm } }

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  it "without vm" do
    ae_service.root['vm'] = nil
    expect { described_class.new(ae_service).main }.to raise_error('VM Object not found')
  end

  it "with retired vm" do
    svc_vm.finish_retirement
    expect { described_class.new(ae_service).main }.to raise_error('VM is already retired')
  end

  it "with retiring vm" do
    svc_vm.start_retirement
    expect { described_class.new(ae_service).main }.to raise_error('VM is already in the process of being retired')
  end

  it "starts retirement" do
    expect(ae_service).to receive(:create_notification).with(:type => :vm_retiring, :subject => svc_vm)
    described_class.new(ae_service).main
    expect(svc_vm.retirement_state).to eq('retiring')
  end
end
