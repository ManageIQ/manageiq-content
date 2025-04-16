require_domain_file
require File.join(ManageIQ::Content::Engine.root, 'content/automate/ManageIQ/System/CommonMethods/Utils.class/__methods__/log_object.rb')
require File.join(ManageIQ::Content::Engine.root, 'content/automate/ManageIQ/Service/Generic/StateMachines/Utils.class/__methods__/util_object.rb')

describe ManageIQ::Automate::Service::Generic::StateMachines::GenericLifecycle::CheckRefreshed do
  let(:admin) { FactoryBot.create(:user_admin) }
  let(:request) { FactoryBot.create(:service_template_provision_request, :requester => admin) }
  let(:ansible_tower_manager) { FactoryBot.create(:automation_manager_ansible_tower) }
  let(:job_template) { FactoryBot.create(:ansible_configuration_script, :manager => ansible_tower_manager) }
  let(:service_ansible_tower) { FactoryBot.create(:service_ansible_tower, :job_template => job_template) }
  let(:task) { FactoryBot.create(:service_template_provision_task, :destination => service_ansible_tower, :miq_request => request) }
  let(:svc_task) { MiqAeMethodService::MiqAeServiceServiceTemplateProvisionTask.find(task.id) }
  let(:svc_service) { MiqAeMethodService::MiqAeServiceServiceAnsibleTower.find(service_ansible_tower.id) }
  let(:ae_service) { Spec::Support::MiqAeMockService.new(root_object) }
  let(:root_object) do
    Spec::Support::MiqAeMockObject.new('service'                         => svc_service,
                                       'service_template_provision_task' => task,
                                       'service_action'                  => 'Provision')
  end

  shared_examples_for "check_refreshed" do
    it "check" do
      allow(svc_task).to receive(:destination).and_return(svc_service)
      allow(svc_service).to receive(:check_refreshed).and_return(status_and_message)

      described_class.new(ae_service).main

      expect(ae_service.root['ae_result']).to eq(ae_result)
    end
  end

  shared_examples_for "check_refreshed_error" do
    it "error" do
      allow(svc_service).to receive(:check_refreshed).and_return(status_and_message)

      expect { described_class.new(ae_service).main }.to raise_error(errormsg)
    end
  end

  context "returns ok when job launching works" do
    let(:status_and_message) { [true, ""] }
    let(:ae_result) { "ok" }
    it_behaves_like "check_refreshed"
  end

  context "returns error when job launching fails" do
    let(:status_and_message) { [true, "error"] }
    let(:ae_result) { "error" }
    it_behaves_like "check_refreshed"
  end

  context "returns retry when job launching is not done" do
    let(:status_and_message) { [false, "retry"] }
    let(:ae_result) { "retry" }
    it_behaves_like "check_refreshed"
  end

  context "invalid service_action" do
    let(:status_and_message) { [true, ""] }
    let(:errormsg)           { 'Invalid service_action' }
    let(:root_object) do
      Spec::Support::MiqAeMockObject.new('service'        => svc_service,
                                         'service_action' => 'fred')
    end
    it_behaves_like "check_refreshed_error"
  end

  context "service not found" do
    let(:status_and_message) { [true, ""] }
    let(:errormsg)           { 'Service not found' }
    let(:root_object) do
      Spec::Support::MiqAeMockObject.new('service_template_provision_task' => task,
                                         'service_action'                  => 'Provision')
    end
    it_behaves_like "check_refreshed_error"
  end
end
