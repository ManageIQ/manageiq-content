require_domain_file

describe ManageIQ::Automate::System::Event::StateMachines::Refresh::CheckRefreshed do
  let(:event) { FactoryBot.create(:event_stream) }
  let(:task)  { FactoryBot.create(:miq_task) }

  let(:svc_event) { MiqAeMethodService::MiqAeServiceEventStream.find(event.id) }
  let(:svc_task)  { MiqAeMethodService::MiqAeServiceMiqTask.find(task.id) }

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(Spec::Support::MiqAeMockObject.new({})).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = Spec::Support::MiqAeMockObject.new({})
      service.object = current_object
    end
  end

  it 'when task is finished with "ok"' do
    ae_service.set_state_var(:refresh_task_id, [task.id])
    task.update_attributes(:state => 'Finished')
    described_class.new(ae_service).main
    expect(ae_service.root['ae_result']).to eq('ok')
  end

  it 'when task is finished with "error"' do
    ae_service.set_state_var(:refresh_task_id, [task.id])
    task.update_attributes(:state => 'Finished', :status => 'Timeout')
    described_class.new(ae_service).main
    expect(ae_service.root['ae_result']).to eq('error')
  end

  it 'when task is active' do
    ae_service.set_state_var(:refresh_task_id, [task.id])
    task.update_attributes(:state => 'Active')
    described_class.new(ae_service).main
    expect(ae_service.root['ae_result']).to eq('retry')
    expect(ae_service.root['ae_retry_interval']).to eq('1.minute')
  end

  it 'when specified task does not exist' do
    ae_service.set_state_var(:refresh_task_id, [99])
    expect { described_class.new(ae_service).main }.to raise_error('Refresh task with id: 99 not found')
  end
end
