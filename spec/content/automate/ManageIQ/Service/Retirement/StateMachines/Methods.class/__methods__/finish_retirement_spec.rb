require_domain_file

describe ManageIQ::Automate::Service::Retirement::StateMachines::Methods::FinishRetirement do
  let(:admin) { FactoryBot.create(:user_admin) }
  let(:request) { FactoryBot.create(:service_retire_request, :requester => admin) }
  let(:service) { FactoryBot.create(:service, 'retirement_state'    => 'retired') }
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
    expect(ae_service).not_to receive(:create_notification)
    expect { described_class.new(ae_service).main }.not_to raise_error
  end

  it "retires vm" do
    expect(svc_service).to receive(:finish_retirement)
    expect(ae_service).to receive(:create_notification).with(:type => :service_retired, :subject => svc_service)
    described_class.new(ae_service).main
    expect(service.retirement_state).to eq("retired")
  end
end
