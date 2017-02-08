require_domain_file

describe ManageIQ::Automate::Service::Generic::StateMachines::GenericLifecycle::CheckCompleted do
  let(:admin) { FactoryGirl.create(:user_admin) }
  let(:request) { FactoryGirl.create(:service_template_provision_request, :requester => admin) }
  let(:ansible_tower_manager) { FactoryGirl.create(:automation_manager) }
  let(:job_template) { FactoryGirl.create(:ansible_configuration_script, :manager => ansible_tower_manager) }
  let(:service_ansible_tower) { FactoryGirl.create(:service_ansible_tower, :job_template => job_template) }
  let(:task) { FactoryGirl.create(:service_template_provision_task, :destination => service_ansible_tower, :miq_request => request) }
  let(:svc_task) { MiqAeMethodService::MiqAeServiceServiceTemplateProvisionTask.find(task.id) }
  let(:svc_service) { MiqAeMethodService::MiqAeServiceServiceAnsibleTower.find(service_ansible_tower.id) }
  let(:root_object) { Spec::Support::MiqAeMockObject.new('service_template_provision_task' => svc_task) }
  let(:ae_service) { Spec::Support::MiqAeMockService.new(root_object) }

  shared_examples_for "check_completed" do
    it "check" do
      allow(svc_task).to receive(:destination).and_return(svc_service)
      allow(svc_service).to receive(:check_completed).and_return(status_and_message)

      described_class.new(ae_service).main

      expect(ae_service.root['ae_result']).to eq(ae_result)
    end
  end

  context "returns ok when job launching works" do
    let(:status_and_message) { [true, ""] }
    let(:ae_result) { "ok" }
    it_behaves_like "check_completed"
  end

  context "returns error when job launching fails" do
    let(:status_and_message) { [true, "error"] }
    let(:ae_result) { "error" }
    it_behaves_like "check_completed"
  end

  context "returns retry when job launching is not done" do
    let(:status_and_message) { [false, "retry"] }
    let(:ae_result) { "retry" }
    it_behaves_like "check_completed"
  end
end
