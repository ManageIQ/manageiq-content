require_domain_file

describe ManageIQ::Automate::System::Event::StateMachines::Refresh::TargetRefresh do
  let(:ems)         { FactoryBot.create(:ems_vmware) }
  let(:vm)          { FactoryBot.create(:vm_vmware, :ext_management_system => ems) }
  let(:event)       { FactoryBot.create(:ems_event, :vm_or_template => vm) }
  let(:svc_event)   { MiqAeMethodService::MiqAeServiceEventStream.find(event.id) }
  let(:root_object) { Spec::Support::MiqAeMockObject.new('event_stream' => event) }
  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      service.object = Spec::Support::MiqAeMockObject.new('refresh_target' => 'src_vm')
    end
  end

  it 'when event object is not found' do
    ae_service.root['event_stream'] = nil
    expect { described_class.new(ae_service).main }.to raise_error(RuntimeError, "Event object not found")
  end

  it 'when refresh target is specified' do
    described_class.new(ae_service).main

    expect(MiqQueue.count).to eq(1)

    queue_item = MiqQueue.first
    expect(queue_item).not_to        be_nil
    expect(queue_item.data.count).to eq(1)

    target_klass, target_id = queue_item.data.first
    expect(target_klass).to eq(vm.class.name)
    expect(target_id).to    eq(vm.id)
  end

  it 'when refresh target is not specified' do
    ae_service.object['refresh_target'] = nil
    expect { described_class.new(ae_service).main }.to raise_error(RuntimeError, "Refresh target not found")
  end

  it 'when specified target does not exist' do
    ae_service.object['refresh_target'] = 'src_host'
    described_class.new(ae_service).main

    expect(MiqQueue.count).to eq(0)
  end
end
