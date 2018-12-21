require_domain_file

describe ManageIQ::Automate::Cloud::Orchestration::Reconfiguration::StateMachines::PostReconfigure do
  let(:request)               { FactoryBot.create(:service_template_provision_request, :requester => user) }
  let(:service_orchestration) { FactoryBot.create(:service_orchestration) }
  let(:user)                  { FactoryBot.create(:user_with_group) }
  let(:output)                { FactoryBot.create(:orchestration_stack_output, :key => 'key', :value => 'value') }
  let(:orchestration_stack)   { FactoryBot.create(:orchestration_stack_amazon, :name => "name", :outputs => [output]) }
  let(:miq_request_task)      { FactoryBot.create(:service_reconfigure_task, :request_type => 'service_reconfigure') }

  let(:root_hash) do
    { 'service_template' => MiqAeMethodService::MiqAeServiceService.find(service_orchestration.id) }
  end

  let(:root_object) do
    obj = Spec::Support::MiqAeMockObject.new(root_hash)
    obj["service_reconfigure_task"] = svc_model_miq_request_task
    obj
  end

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  let(:svc_model_service)          { MiqAeMethodService::MiqAeServiceService.find(service_orchestration.id) }
  let(:svc_model_amazon_stack)     { MiqAeMethodService::MiqAeServiceOrchestrationStack.find(orchestration_stack.id) }
  let(:svc_model_output)           { MiqAeMethodService::MiqAeServiceOrchestrationStackOutput.find(output.id) }
  let(:svc_model_miq_request_task) { MiqAeMethodService::MiqAeServiceMiqRequestTask.find(miq_request_task.id) }

  before do
    allow(ae_service).to receive(:inputs) { {'debug' => true} }
  end

  it "calling the dump_stack_outputs method" do
    allow(svc_model_miq_request_task).to receive(:source)     { svc_model_service }
    allow(svc_model_service).to receive(:orchestration_stack) { svc_model_amazon_stack }
    allow(svc_model_amazon_stack).to receive(:outputs)        { [svc_model_output] }

    instance = described_class.new(ae_service)
    expect(instance).to receive(:dump_stack_outputs).with(svc_model_amazon_stack)
    instance.main
  end

  it "service_reconfigure_task is nil" do
    service = ae_service
    service.root['service_reconfigure_task'] = nil
    expect { described_class.new(service).main }.to raise_error('Service Reconfigure Task not found')
  end

  it "service is nil" do
    allow(svc_model_miq_request_task).to receive(:source) { nil }
    expect { described_class.new(ae_service).main }.to raise_error('Service not found')
  end

  it "orchestration_stack is nil" do
    allow(svc_model_miq_request_task).to receive(:source)     { svc_model_service }
    allow(svc_model_service).to receive(:orchestration_stack) { nil }
    expect { described_class.new(ae_service).main }.to raise_error('Orchestration Stack not found')
  end
end
