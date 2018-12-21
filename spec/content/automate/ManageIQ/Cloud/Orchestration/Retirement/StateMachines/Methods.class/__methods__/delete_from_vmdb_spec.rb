require_domain_file

describe ManageIQ::Automate::Cloud::Orchestration::Retirement::StateMachines::Methods::DeleteFromVmdb do
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

  it "removes stack from vmdb" do
    ae_service.set_state_var('stack_exists_in_provider', false)
    described_class.new(ae_service).main

    expect(ae_service.root['orchestration_stack']).to eq(nil)
  end
end
