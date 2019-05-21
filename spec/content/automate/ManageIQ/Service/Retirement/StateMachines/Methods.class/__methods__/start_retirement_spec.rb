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
                                       'service_retire_task' => svc_task)
  end
  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  let(:svc_model_request) do
    MiqAeMethodService::MiqAeServiceServiceRetireRequest.find(request.id)
  end

  it "#Service retiring - good" do
    expect(service.retirement_state).to be_nil
    service.start_retirement

    expect(service.retirement_state).to eq("retiring")
  end

  it "starts retirement" do
    allow(ae_service).to receive(:create_notification)
  end

  context "with no service" do
    let(:root_object) do
      Spec::Support::MiqAeMockObject.new('service'             => nil,
                                         'service_retire_task' => svc_task)
    end

    it "raises the ERROR - Service Object not found" do
      expect { described_class.new(ae_service).main }.to raise_error(
        'Service Object not found'
      )
    end
  end

  it "raises the ERROR - Service is already retired. Aborting current State Machine." do
    service.update(
      :retired              => true,
      :retirement_last_warn => Time.zone.now,
      :retirement_state     => "retired"
    )
    service.reload

    expect { described_class.new(ae_service).main }.to raise_error(
      'Service is already retired. Aborting current State Machine.'
    )
  end

  it "raises the ERROR - Service is in the process of being retired. Aborting current State Machine." do
    service.update(
      :retired              => false,
      :retirement_last_warn => Time.zone.now,
      :retirement_state     => "retiring"
    )
    service.reload

    expect { described_class.new(ae_service).main }.to raise_error(
      'Service is in the process of being retired. Aborting current State Machine.'
    )
  end
end
