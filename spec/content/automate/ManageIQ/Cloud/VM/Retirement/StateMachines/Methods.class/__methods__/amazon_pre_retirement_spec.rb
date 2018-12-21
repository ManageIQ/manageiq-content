require_domain_file

describe ManageIQ::Automate::Cloud::VM::Retirement::StateMachines::Methods::AmazonPreRetirement do
  let(:svc_vm)      { MiqAeMethodService::MiqAeServiceVm.find(vm.id) }
  let(:ems)         { FactoryBot.create(:ems_amazon, :name => 'testEmsAmazon') }
  let(:root_object) { Spec::Support::MiqAeMockObject.new(root_hash) }
  let(:root_hash)   { { 'vm' => svc_vm } }
  let(:vm) do
    FactoryBot.create(:vm_amazon, :ems_id          => ems.id,
                                   :name            => 'testVmAmazon',
                                   :raw_power_state => "running",
                                   :registered      => true)
  end
  let(:ebs_hardware) do
    FactoryBot.create(:hardware, :bitness             => 64,
                                  :virtualization_type => 'paravirtual',
                                  :root_device_type    => 'ebs')
  end
  let(:is_hardware) do
    FactoryBot.create(:hardware, :bitness             => 64,
                                  :virtualization_type => 'paravirtual',
                                  :root_device_type    => 'instance-store')
  end
  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  it "calls stop for ebs hardware type" do
    vm.hardware = ebs_hardware
    expect(svc_vm).to(receive(:stop))
    described_class.new(ae_service).main
  end

  context "does not call stop" do
    shared_examples_for 'has nil VM or EMS' do
      it 'log validation' do
        expect(ae_service).to(
          receive(:log).with(
            'info',
            "Skipping Amazon pre retirement for Instance:<"\
            "#{svc_vm.try(:name)}> on EMS:<> with instance store type <>"
          )
        )
        described_class.new(ae_service).main
      end
    end

    context '#nil VM' do
      let(:root_hash) {}
      let(:svc_vm)    {}
      it_behaves_like 'has nil VM or EMS'
    end

    context '#nil EMS' do
      let(:vm) do
        FactoryBot.create(:vm_amazon, :name            => 'testVmAmazon',
                                       :raw_power_state => "running",
                                       :registered      => true)
      end
      it_behaves_like 'has nil VM or EMS'
    end

    it '#nil hardware' do
      expect { described_class.new(ae_service).main }.to raise_error('Aborting Amazon pre retirement')
    end

    it "#instance-store hardware type" do
      vm.hardware = is_hardware
      expect(ae_service).to(
        receive(:log).with(
          'info',
          "Skipping stopping of non EBS Amazon Instance <#{vm.name}> in EMS "\
          "<#{ems.name}> with instance store type <#{vm.hardware.root_device_type}>"
        )
      )
      described_class.new(ae_service).main
    end
  end
end
