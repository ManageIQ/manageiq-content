require_default_domain_file('Cloud/Orchestration/Lifecycle.class/__methods__/orchestration_mixin.rb')
require_domain_file

describe ManageIQ::Automate::Cloud::Orchestration::Retirement::StateMachines::Methods::FinishRetirement do
  let(:stack)                 { FactoryGirl.create(:orchestration_stack_amazon) }
  let(:service_orchestration) { FactoryGirl.create(:service_orchestration) }
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

  it "retires orchestration stack" do
    expect(ae_service).to receive(:create_notification)
    described_class.new(ae_service).main

    expect(svc_model_stack.retired).to eq(true)
    expect(svc_model_stack.retires_on).to be_between(Time.zone.now - 10.seconds, Time.zone.now + 1.second)
    expect(svc_model_stack.retirement_state).to eq("retired")
  end
end
