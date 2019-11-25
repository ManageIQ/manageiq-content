require_domain_file

describe ManageIQ::Automate::Service::Retirement::StateMachines::Methods::StartRetirement do
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

  it "without service" do
    ae_service.root['service'] = nil
    expect { described_class.new(ae_service).main }.to raise_error('Service Object not found')
  end

  it "without task" do
    ae_service.root['service_retire_task'] = nil
    expect { described_class.new(ae_service).main }.to raise_error('Service retire task not found, The old style retirement is incompatible with the new retirement state machine.')
  end

  it "with retired service" do
    svc_service.finish_retirement
    expect { described_class.new(ae_service).main }.to raise_error('Service is already retired')
  end

  it "with retiring service" do
    svc_service.start_retirement
    expect { described_class.new(ae_service).main }.to raise_error('Service is already in the process of being retired')
  end

  it "starts retirement" do
    expect(ae_service).to receive(:create_notification).with(:type => :service_retiring, :subject => svc_service)
    described_class.new(ae_service).main
    expect(svc_service.retirement_state).to eq('retiring')
  end
end
