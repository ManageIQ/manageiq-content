require_domain_file

describe ManageIQ::Automate::Cloud::VM::Retirement::StateMachines::Methods::DeleteFromVmdb do
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

  it 'removes vm from vmdb' do
    ae_service.set_state_var('vm_removed_from_provider', true)
    expect(svc_vm).to(receive(:remove_from_vmdb))
    described_class.new(ae_service).main
  end

  context 'does not remove vm from vmdb' do
    it '#nil vm' do
      root_hash['vm'] = nil
      expect(ae_service).not_to(receive(:log))
      described_class.new(ae_service).main
    end

    it '#without vm_removed_from_provider state_var' do
      expect(svc_vm).not_to(receive(:remove_from_provider))
      expect(ae_service).not_to(receive(:log))
      described_class.new(ae_service).main
    end
  end
end
