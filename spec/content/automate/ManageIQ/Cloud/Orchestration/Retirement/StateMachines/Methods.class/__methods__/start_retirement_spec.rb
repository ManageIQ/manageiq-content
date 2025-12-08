require_domain_file

describe ManageIQ::Automate::Cloud::Orchestration::Retirement::StateMachines::Methods::StartRetirement do
  let(:stack)                 { FactoryBot.create(:orchestration_stack_amazon) }
  let(:service_orchestration) { FactoryBot.create(:service_orchestration) }
  let(:svc_model_service)     { MiqAeMethodService::MiqAeServiceService.find(service_orchestration.id) }
  let(:svc_model_stack)       { MiqAeMethodService::MiqAeServiceOrchestrationStack.find(stack.id) }

  let(:root_hash) do
    { 'service_template' => MiqAeMethodService::MiqAeServiceService.find(service_orchestration.id) }
  end

  let(:root_object) do
    obj = Spec::Support::MiqAeMockObject.new(root_hash)
    obj["orchestration_stack"] = svc_model_stack
    obj
  end

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  it "without stack" do
    ae_service.root['orchestration_stack'] = nil
    expect { described_class.new(ae_service).main }.to raise_error('OrchestrationStack Object not found')
  end

  it "with retired stack" do
    svc_model_stack.finish_retirement
    expect { described_class.new(ae_service).main }.to raise_error('Stack is already retired. Aborting current State Machine.')
  end

  it "with retiring stack" do
    svc_model_stack.start_retirement
    expect { described_class.new(ae_service).main }.to raise_error('Stack is in the process of being retired. Aborting current State Machine.')
  end

  it "starts retirement" do
    expect(ae_service).to receive(:create_notification).with(:type => :orchestration_stack_retiring, :subject => svc_model_stack)
    expect(svc_model_stack).to receive(:start_retirement)
    expect { described_class.new(ae_service).main }.to_not raise_error
  end
end
