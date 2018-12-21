require_domain_file

describe ManageIQ::Automate::Cloud::VM::Retirement::StateMachines::Methods::OpenstackPreRetirement do
  let(:svc_vm)         { MiqAeMethodService::MiqAeServiceVm.find(vm.id) }
  let(:ems)            { FactoryBot.create(:ems_vmware) }
  let(:vm)             { FactoryBot.create(:vm_vmware, :ems_id => ems.id) }
  let(:root_object)    { Spec::Support::MiqAeMockObject.new(root_hash) }
  let(:root_hash)      { { 'vm' => svc_vm } }

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  it 'call suspend for running instances' do
    expect(svc_vm).to receive(:suspend)
    described_class.new(ae_service).main
  end

  context "Doesn't call suspend for " do
    shared_examples_for 'Not calling suspend' do
      it 'call check' do
        expect(svc_vm).not_to receive(:suspend)
        described_class.new(ae_service).main
      end
    end

    context 'poweredOff vm' do
      let(:vm) { FactoryBot.create(:vm_vmware, :ems_id => ems.id, :raw_power_state => 'poweredOff') }
      it_behaves_like 'Not calling suspend'
    end

    context 'nil vm' do
      let(:root_hash) { {} }
      it_behaves_like 'Not calling suspend'
    end

    context 'nil ems' do
      let(:vm) { FactoryBot.create(:vm_vmware) }
      it_behaves_like 'Not calling suspend'
    end
  end
end
