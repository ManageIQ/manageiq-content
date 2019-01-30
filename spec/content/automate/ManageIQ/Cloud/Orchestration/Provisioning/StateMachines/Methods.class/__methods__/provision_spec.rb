require_domain_file

describe ManageIQ::Automate::Cloud::Orchestration::Provisioning::StateMachines::Provision do
  let(:job_class)        { ManageIQ::Providers::CloudManager::OrchestrationTemplateRunner }
  let(:request)          { FactoryBot.create(:service_template_provision_request, :requester => user) }
  let(:manager)          { FactoryBot.create(:ems_amazon) }
  let(:user)             { FactoryBot.create(:user_with_group) }
  let(:template)         { FactoryBot.create(:orchestration_template) }
  let(:service_template) { FactoryBot.create(:service_template_orchestration, :orchestration_manager => manager, :orchestration_template => template) }
  let(:job)              { FactoryBot.create(:job) }

  let(:service_orchestration) do
    FactoryBot.create(:service_orchestration, :orchestration_manager => manager, :service_template => service_template, :orchestration_template => template)
  end

  let(:svc_model_service) { MiqAeMethodService::MiqAeServiceService.find(service_orchestration.id) }
  let(:task)              { FactoryBot.create(:service_template_provision_task, :destination => service_orchestration, :miq_request => request) }
  let(:svc_model_task)    { MiqAeMethodService::MiqAeServiceServiceTemplateProvisionTask.find(task.id) }
  let(:root_object)       { Spec::Support::MiqAeMockObject.new('service_template_provision_task' => svc_model_task) }
  let(:ae_service)        { Spec::Support::MiqAeMockService.new(root_object) }

  it "launches an orchestration template runner job" do
    expect(job_class).to receive(:create_job).and_return(job)
    described_class.new(ae_service).main
  end

  it "fails the step when job launching fails" do
    expect(job_class).to receive(:create_job).and_raise('provider error')
    described_class.new(ae_service).main
    expect(ae_service.root['ae_result']).to eq('error')
    expect(ae_service.root['ae_reason']).to eq('provider error')
  end
end
