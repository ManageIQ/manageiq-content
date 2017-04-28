require_domain_file

describe ManageIQ::Automate::Cloud::Orchestration::Retirement::StateMachines::Methods::CheckRemovedFromProvider do
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

  before do
    ae_service.set_state_var('stack_exists_in_provider', 'stack_exists_in_provider_value')
  end

  it "sets ae_result to ok" do
    allow(svc_model_stack).to receive(:normalized_live_status) { %w(not_exist reason) }
    described_class.new(ae_service).main

    expect(ae_service.root['ae_result']).to eq('ok')
    expect(ae_service.get_state_var('stack_exists_in_provider')).to eq(false)
  end

  it "sets ae_result to retry" do
    allow(svc_model_stack).to receive(:normalized_live_status) { %w(status reason) }
    described_class.new(ae_service).main

    expect(ae_service.root['ae_result']).to eq('retry')
    expect(ae_service.root['ae_retry_interval']).to eq('1.minute')
  end

  it "sets ae_result to error" do
    allow(svc_model_stack).to receive(:normalized_live_status) { raise 'Exception!' }
    described_class.new(ae_service).main

    expect(ae_service.root['ae_result']).to eq('error')
    expect(ae_service.root['ae_reason']).to eq('Exception!')
  end
end
