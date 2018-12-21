require_domain_file

describe ManageIQ::Automate::Cloud::VM::Retirement::StateMachines::Methods::RemoveFromProvider do
  let(:zone)        { FactoryBot.create(:zone) }
  let(:svc_vm)      { MiqAeMethodService::MiqAeServiceVm.find(vm.id) }
  let(:root_hash)   { { 'vm' => svc_vm } }
  let(:root_object) { Spec::Support::MiqAeMockObject.new(root_hash) }

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  shared_examples 'ae_method' do
    it "without removal_type" do
      expect(ae_service).to receive(:log).with('info', "Unknown retirement type for VM:<#{vm.name}> from provider:<#{ems.name}>")
      expect { described_class.new(ae_service).main }.to raise_error('Unknown retirement type')
      expect(ae_service.get_state_var('vm_removed_from_provider')).to be_falsey
    end

    it "vm without tags" do
      ae_service.inputs['removal_type'] = 'remove_from_disk'
      described_class.new(ae_service).main
      expect(ae_service.get_state_var('vm_removed_from_provider')).to be_falsey
    end

    it "nil vm" do
      ae_service.root['vm'] = nil
      expect(ae_service).to receive(:log).with('info', 'Skipping remove from provider for Instance:<> on provider:<>')
      described_class.new(ae_service).main
      expect(ae_service.get_state_var('vm_removed_from_provider')).to be_falsey
    end

    it "removes a vm" do
      ae_service.inputs['removal_type'] = 'remove_from_disk'
      vm.tag_with("retire_full", :ns => "/managed", :cat => "lifecycle")
      expect { described_class.new(ae_service).main }.to_not raise_error
      expect(ae_service.get_state_var('vm_removed_from_provider')).to be_truthy
    end

    context "without ems" do
      let(:vm) { FactoryBot.create(:vm_vmware) }

      it "skips removing" do
        expect(ae_service).to receive(:log).with('info', "Skipping remove from provider for Instance:<#{svc_vm.try(:name)}> on provider:<>")
        described_class.new(ae_service).main
        expect(ae_service.get_state_var('vm_removed_from_provider')).to be_falsey
      end
    end
  end

  context "Infrastructure" do
    let(:ems) { FactoryBot.create(:ems_vmware, :zone => zone) }
    let(:vm) { FactoryBot.create(:vm_vmware, :ems_id => ems.id) }

    it_behaves_like 'ae_method'
  end

  context "Cloud" do
    let(:ems) { FactoryBot.create(:ems_google, :zone => zone) }
    let(:vm) { FactoryBot.create(:vm_google, :ems_id => ems.id) }

    it_behaves_like 'ae_method'
  end
end
