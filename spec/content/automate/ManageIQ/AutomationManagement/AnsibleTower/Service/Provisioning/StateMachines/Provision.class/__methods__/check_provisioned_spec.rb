require_domain_file

describe ManageIQ::Automate::AutomationManagement::AnsibleTower::Service::Provisioning::StateMachines::Provision::CheckProvisioned do
  let(:admin) { FactoryBot.create(:user_admin) }
  let(:request) { FactoryBot.create(:service_template_provision_request, :requester => admin) }
  let(:service_ansible_tower) { FactoryBot.create(:service_ansible_tower) }
  let(:task) { FactoryBot.create(:service_template_provision_task, :destination => service_ansible_tower, :miq_request => request) }
  let(:svc_task) { MiqAeMethodService::MiqAeServiceServiceTemplateProvisionTask.find(task.id) }
  let(:root_object) { Spec::Support::MiqAeMockObject.new('service_template_provision_task' => svc_task) }
  let(:ae_service) { Spec::Support::MiqAeMockService.new(root_object) }
  let(:job_class) { MiqAeMethodService::MiqAeServiceManageIQ_Providers_AnsibleTower_AutomationManager_Job }
  let(:job) { FactoryBot.create(:ansible_tower_job) }
  let(:workflow_job_class) { MiqAeMethodService::MiqAeServiceManageIQ_Providers_AnsibleTower_AutomationManager_WorkflowJob }
  let(:workflow_job) { FactoryBot.create(:ansible_tower_workflow_job) }

  shared_examples_for "check_provisioned" do
    it "check" do
      expect_any_instance_of(ServiceAnsibleTower).to receive(:job).and_return(job_type)
      expect_any_instance_of(job_class_type).to receive(:normalized_live_status).with(no_args).and_return(status)
      described_class.new(ae_service).main
      expect(ae_service.root['ae_result']).to eq(result)
      expect(ae_service.root['ae_reason']).to eq(reason)
    end
  end

  context "ansible tower job completed" do
    before { expect(job).to receive(:refresh_ems) }
    let(:status) { %w(create_complete ok) }
    let(:job_type) { job }
    let(:job_class_type) { job_class }
    let(:result) { 'ok' }
    let(:reason) { nil }
    it_behaves_like "check_provisioned"
  end

  context "ansible tower job is running" do
    let(:status) { %w(running ok) }
    let(:job_type) { job }
    let(:job_class_type) { job_class }
    let(:result) { 'retry' }
    let(:reason) { nil }
    it_behaves_like "check_provisioned"
  end

  context "ansible tower job failed" do
    before { expect(job).to receive(:refresh_ems) }
    before { expect(job).to receive(:raw_stdout) }
    let(:status) { %w(create_failed bad) }
    let(:job_type) { job }
    let(:job_class_type) { job_class }
    let(:result) { 'error' }
    let(:reason) { 'bad' }
    it_behaves_like "check_provisioned"
  end

  context "ansible tower workflow job completed" do
    before { expect(workflow_job).to receive(:refresh_ems) }
    let(:status) { %w(create_complete ok) }
    let(:job_type) { workflow_job }
    let(:job_class_type) { workflow_job_class }
    let(:result) { 'ok' }
    let(:reason) { nil }
    it_behaves_like "check_provisioned"
  end

  context "ansible tower workflow job is running" do
    let(:status) { %w(running ok) }
    let(:job_type) { workflow_job }
    let(:job_class_type) { workflow_job_class }
    let(:result) { 'retry' }
    let(:reason) { nil }
    it_behaves_like "check_provisioned"
  end

  context "ansible tower workflow job failed" do
    before { expect(workflow_job).to receive(:refresh_ems) }
    before { expect(workflow_job).not_to receive(:raw_stdout) }
    let(:status) { %w(create_failed bad) }
    let(:job_type) { workflow_job }
    let(:job_class_type) { workflow_job_class }
    let(:result) { 'error' }
    let(:reason) { 'bad' }
    it_behaves_like "check_provisioned"
  end
end
