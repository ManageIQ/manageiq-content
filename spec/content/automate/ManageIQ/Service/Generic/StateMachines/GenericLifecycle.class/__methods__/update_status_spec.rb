require_domain_file
require File.join(ManageIQ::Content::Engine.root, 'content/automate/ManageIQ/System/CommonMethods/Utils.class/__methods__/log_object.rb')

describe ManageIQ::Automate::Service::Generic::StateMachines::GenericLifecycle::UpdateStatus do
  let(:admin) { FactoryGirl.create(:user_admin) }
  let(:request) { FactoryGirl.create(:service_template_provision_request, :requester => admin) }
  let(:ansible_tower_manager) { FactoryGirl.create(:automation_manager) }
  let(:job_template) { FactoryGirl.create(:ansible_configuration_script, :manager => ansible_tower_manager) }
  let(:service_ansible_tower) { FactoryGirl.create(:service_ansible_tower, :job_template => job_template) }
  let(:task) { FactoryGirl.create(:service_template_provision_task, :destination => service_ansible_tower, :miq_request => request) }
  let(:svc_task) { MiqAeMethodService::MiqAeServiceServiceTemplateProvisionTask.find(task.id) }
  let(:svc_service) { MiqAeMethodService::MiqAeServiceServiceAnsibleTower.find(service_ansible_tower.id) }
  let(:root_object) do
    Spec::Support::MiqAeMockObject.new('service'                         => service_object,
                                       'service_action'                  => service_action,
                                       'service_template_provision_task' => svc_task,
                                       'miq_server'                      => svc_model_miq_server)
  end
  let(:ae_service) { Spec::Support::MiqAeMockService.new(root_object) }
  let(:svc_model_request) { MiqAeMethodService::MiqAeServiceServiceTemplateProvisionRequest.find(request.id) }
  let(:miq_server) { EvmSpecHelper.local_miq_server }
  let(:svc_model_miq_server) { MiqAeMethodService::MiqAeServiceMiqServer.find(miq_server.id) }
  let(:service_action) { 'Provision' }
  let(:service_object) { svc_service }

  shared_examples_for "update_status_on_error" do
    it "on_error" do
      allow(svc_task).to receive(:destination).and_return(svc_service)
      root_object['ae_result'] = 'error'
      allow(ae_service).to receive(:create_notification)
      allow(ae_service).to receive(:inputs) { {'status' => "fred"} }
      expect(svc_service).to receive(:on_error).with(service_action)
      described_class.new(ae_service).main
    end
  end

  context "Log_and_raise ERROR - " do
    let(:service_action) { 'Not_Provision' }
    it "Invalid service action " do
      allow(ManageIQ::Automate::System::CommonMethods::Utils::LogObject).to receive(:log_and_raise).with(/ERROR - Invalid service action/, ae_service).and_raise(RuntimeError)
      expect { described_class.new(ae_service).main }.to raise_error(RuntimeError)
    end
  end

  context "Log_and_raise " do
    let(:service_object) { nil }
    it "Service not found" do
      allow(ManageIQ::Automate::System::CommonMethods::Utils::LogObject).to receive(:log_and_raise).with(/ERROR - Service not found/, ae_service).and_raise(RuntimeError)
      expect { described_class.new(ae_service).main }.to raise_error(RuntimeError)
    end
  end

  context "update_status" do
    it "successful scenario" do
      allow(svc_task).to receive(:destination).and_return(svc_service)
      allow(svc_service).to receive(:update_status).and_return(nil)
      allow(ae_service).to receive(:inputs) { {'status' => "fred"} }

      described_class.new(ae_service).main

      msg = "Server [#{miq_server.name}] Service [#{svc_service.name}] Provision Step [] Status [fred] "
      expect(svc_model_request.reload.message).to eq(msg)
      expect(svc_service).not_to receive(:on_error)
    end
  end

  context "on_error provisioning" do
    let(:service_action) { 'Provision' }
    it_behaves_like "update_status_on_error"
  end

  context "on_error retirement" do
    let(:service_action) { 'Retirement' }
    it_behaves_like "update_status_on_error"
  end
end
