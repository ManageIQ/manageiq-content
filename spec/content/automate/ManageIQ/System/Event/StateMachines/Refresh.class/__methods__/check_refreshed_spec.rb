require_domain_file

describe ManageIQ::Automate::System::Event::StateMachines::Refresh::CheckRefreshed do
  let(:ems)             { FactoryBot.create(:ems_vmware) }
  let(:vm)              { FactoryBot.create(:vm_vmware, :ext_management_system => ems) }
  let(:event_timestamp) { Time.now.utc }
  let(:event)           { FactoryBot.create(:event_stream, :vm => vm, :ext_management_system => ems, :timestamp => event_timestamp) }
  let(:svc_event)       { MiqAeMethodService::MiqAeServiceEventStream.find(event.id) }
  let(:root_object)     { Spec::Support::MiqAeMockObject.new('event_stream' => event) }

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = Spec::Support::MiqAeMockObject.new({})
      service.object = current_object
    end
  end

  it 'when event object is not found' do
    ae_service.root['event_stream'] = nil
    expect { described_class.new(ae_service).main }.to raise_error(RuntimeError, "Event object not found")
  end

  it 'when ems is refreshed after the event' do
    ems.update(:last_inventory_date => event_timestamp + 1.minute)
    described_class.new(ae_service).main
    expect(ae_service.root['ae_result']).to eq('ok')
  end

  it 'when ems is not refreshed after the event' do
    ems.update(:last_inventory_date => event_timestamp - 1.minute)
    described_class.new(ae_service).main
    expect(ae_service.root['ae_result']).to eq('retry')
    expect(ae_service.root['ae_retry_interval']).to eq('1.minute')
  end
end
