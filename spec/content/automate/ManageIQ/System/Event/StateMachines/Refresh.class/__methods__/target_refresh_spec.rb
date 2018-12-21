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
    expect(ae_service.get_state_var(:refresh_task_id)).to be_truthy
  end

  it 'when refresh target is not specified' do
    ae_service.object['refresh_target'] = nil
    expect { described_class.new(ae_service).main }.to raise_error(RuntimeError, "Refresh target not found")
  end

  it 'when specified target does not exist' do
    ae_service.object['refresh_target'] = 'src_host'
    expect { described_class.new(ae_service).main }.to raise_error(RuntimeError, "Refresh task not created")
  end
end
