require_domain_file

describe ManageIQ::Automate::Cloud::VM::Retirement::StateMachines::Methods::CheckRemovedFromProvider do
  let(:svc_vm)         { MiqAeMethodService::MiqAeServiceVm.find(vm.id) }
  let(:ems)            { FactoryGirl.create(:ems_vmware) }
  let(:vm)             { FactoryGirl.create(:vm_vmware, :ems_id => ems.id) }
  let(:root_object)    { Spec::Support::MiqAeMockObject.new(root_hash) }
  let(:root_hash)      { { 'vm' => svc_vm } }

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  it "returns 'ok'" do
    described_class.new(ae_service).main
    expect(ae_service.root['ae_result']).to(eq('ok'))
  end

  it "returns 'retry'" do
    ae_service.set_state_var('vm_removed_from_provider', true)
    allow(svc_vm).to receive(:refresh)
    described_class.new(ae_service).main
    expect(ae_service.root['ae_result']).to(eq('retry'))
    expect(ae_service.root['ae_retry_interval']).to(eq('1.minute'))
  end
end
