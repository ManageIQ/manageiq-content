require_domain_file

describe ManageIQ::Automate::Cloud::VM::Retirement::StateMachines::Methods::FinishRetirement do
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

  it "retires vm" do
    expect(svc_vm).to receive(:finish_retirement)
    expect(ae_service).to receive(:create_notification).with(:type => :vm_retired, :subject => svc_vm)
    described_class.new(ae_service).main
  end

  describe "doesn't retire vm" do
    let(:root_hash) {}

    it 'vm is nil' do
      expect(ae_service).not_to receive(:create_notification)
      described_class.new(ae_service).main
    end
  end
end
