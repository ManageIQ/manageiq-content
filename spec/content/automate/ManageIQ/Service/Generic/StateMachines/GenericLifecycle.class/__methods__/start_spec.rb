require_domain_file

describe ManageIQ::Automate::Service::Generic::StateMachines::GenericLifecycle::Start do
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

  context "Start" do
    it "creates notification " do
      expect(ae_service).to receive(:create_notification)
      described_class.new(ae_service).main
    end
  end
end
