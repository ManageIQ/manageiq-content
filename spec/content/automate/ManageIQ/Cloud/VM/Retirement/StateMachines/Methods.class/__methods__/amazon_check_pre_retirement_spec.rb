require_domain_file

describe ManageIQ::Automate::Cloud::VM::Retirement::StateMachines::Methods::AmazonCheckPreRetirement do
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

  shared_examples_for "ae_method" do |ae_result, vm_power_state, ae_retry_interval|
    it "has valid output" do
      described_class.new(ae_service).main
      expect(ae_service.root['ae_result']).to eq(ae_result) if ae_result
      expect(ae_service.root['vm'].power_state).to eq(vm_power_state) if vm_power_state
      expect(ae_service.root['ae_retry_interval']).to eq(ae_retry_interval) if ae_retry_interval
    end
  end

  context "returns 'ok' for instance store instances even with power on" do
    before { vm.hardware = is_hardware }
    it_behaves_like 'ae_method', 'ok', 'on'
  end

  context "returns 'retry' for running ebs instances" do
    before do
      vm.hardware = ebs_hardware
      expect(svc_vm).to(receive(:refresh))
    end
    it_behaves_like 'ae_method', 'retry', 'on', '60.seconds'
  end

  context "returns 'ok' for stopped ebs instances" do
    let(:vm) do
      FactoryBot.create(:vm_amazon, :ems_id          => ems.id,
                                     :raw_power_state => "off",
                                     :registered      => true,
                                     :hardware        => ebs_hardware)
    end
    it_behaves_like 'ae_method', 'ok', 'off'
  end

  context "returns 'ok' for ebs instance with unknown power state" do
    let(:vm) do
      FactoryBot.create(:vm_amazon, :ems_id          => ems.id,
                                     :raw_power_state => "unknown",
                                     :registered      => true,
                                     :hardware        => ebs_hardware)
    end
    it_behaves_like 'ae_method', 'ok', 'terminated'
  end

  context "returns 'error' for VM template" do
    let(:vm) do
      FactoryBot.create(:template_amazon, :ems_id   => ems.id,
                                           :hardware => ebs_hardware)
    end
    let(:svc_vm) { MiqAeMethodService::MiqAeServiceVmOrTemplate.find(vm.id) }

    it "raise error with template" do
      expect { described_class.new(ae_service).main }.to(raise_error('Trying to power off a template'))
      expect(ae_service.root['ae_result']).to(eq('error'))
    end
  end

  context "skips check" do
    before do
      message = "Skipping check pre retirement for Instance:"\
                "<#{vm.try(:name)}> on EMS:<#{ems.try(:name)}>"
      expect(ae_service).to(receive(:log).with('info', message))
    end

    context '#nil vm' do
      let(:vm)      {}
      let(:svc_vm)  {}
      let(:ems)     {}
      it_behaves_like 'ae_method'
    end

    context '#nil ems' do
      let(:vm)  { FactoryBot.create(:vm_amazon, :name => 'testVmAmazon') }
      let(:ems) {}
      it_behaves_like 'ae_method'
    end
  end
end
