require_domain_file

describe ManageIQ::Automate::Service::Retirement::StateMachines::Methods::DeleteServiceFromVmdb do
  let(:admin) { FactoryBot.create(:user_admin) }
  let(:request) { FactoryBot.create(:service_retire_request, :requester => admin) }
  let(:service) { FactoryBot.create(:service) }
  let(:task) { FactoryBot.create(:service_retire_task, :destination => service, :miq_request => request) }
  let(:svc_task) { MiqAeMethodService::MiqAeServiceServiceRetireTask.find(task.id) }
  let(:svc_service) { MiqAeMethodService::MiqAeServiceService.find(service.id) }
  let(:root_object) do
    Spec::Support::MiqAeMockObject.new('service'             => svc_service,
                                       'service_retire_task' => svc_task,
                                       'service_action'      => 'Retirement')
  end
  let(:ae_service) { Spec::Support::MiqAeMockService.new(root_object) }

  it 'removes service from vmdb' do
    expect(ae_service).to(receive(:log))
    expect(svc_service).to(receive(:remove_from_vmdb))
    described_class.new(ae_service).main
  end

  it 'without service' do
    ae_service.root['service'] = nil
    expect(svc_service).not_to(receive(:remove_from_provider))
    expect(ae_service).not_to(receive(:log))
    described_class.new(ae_service).main
  end
end
