require_domain_file
require File.join(ManageIQ::Content::Engine.root, 'content/automate/ManageIQ/System/CommonMethods/Utils.class/__methods__/log_object.rb')

describe ManageIQ::Automate::Service::Generic::StateMachines::GenericLifecycle::Start do
  let(:admin) { FactoryBot.create(:user_admin) }
  let(:request) { FactoryBot.create(:service_template_provision_request, :requester => admin) }
  let(:ansible_tower_manager) { FactoryBot.create(:automation_manager_ansible_tower) }
  let(:job_template) { FactoryBot.create(:ansible_configuration_script, :manager => ansible_tower_manager) }
  let(:service_ansible_tower) { FactoryBot.create(:service_ansible_tower, :job_template => job_template) }
  let(:task) { FactoryBot.create(:service_template_provision_task, :destination => service_ansible_tower, :miq_request => request) }
  let(:svc_task) { MiqAeMethodService::MiqAeServiceServiceTemplateProvisionTask.find(task.id) }
  let(:svc_service) { MiqAeMethodService::MiqAeServiceServiceAnsibleTower.find(service_ansible_tower.id) }
  let(:root_object) { Spec::Support::MiqAeMockObject.new('service' => svc_service, 'service_action' => 'Provision') }
  let(:ae_service) { Spec::Support::MiqAeMockService.new(root_object) }

  context "Start" do
    it "creates notification " do
      allow(ae_service).to receive(:create_notification)

      described_class.new(ae_service).main
      expect(ae_service.root['ae_result']).to eq("ok")
    end
  end

  context "Log_and_raise ERROR - " do
    let(:root_object) { Spec::Support::MiqAeMockObject.new('service' => svc_service, 'service_action' => 'Not_Provision') }
    it "Invalid service action " do
      allow(ManageIQ::Automate::System::CommonMethods::Utils::LogObject).to receive(:log_and_raise).with(/ERROR - Invalid service action/, ae_service).and_raise(RuntimeError)

      expect { described_class.new(ae_service).main }.to raise_error(RuntimeError)
    end
  end

  context "Log_and_raise" do
    let(:root_object) { Spec::Support::MiqAeMockObject.new }
    it "Service not found" do
      allow(ManageIQ::Automate::System::CommonMethods::Utils::LogObject).to receive(:log_and_raise).with(/ERROR - Service not found/, ae_service).and_raise(RuntimeError)

      expect { described_class.new(ae_service).main }.to raise_error(RuntimeError)
    end
  end
end
