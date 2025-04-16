require_domain_file
require File.join(ManageIQ::Content::Engine.root, 'content/automate/ManageIQ/System/CommonMethods/Utils.class/__methods__/log_object.rb')
require File.join(ManageIQ::Content::Engine.root, 'content/automate/ManageIQ/Service/Generic/StateMachines/Utils.class/__methods__/util_object.rb')

describe ManageIQ::Automate::Service::Generic::StateMachines::GenericLifecycle::CheckCompleted do
  let(:admin) { FactoryBot.create(:user_admin) }
  let(:request) { FactoryBot.create(:service_template_provision_request, :requester => admin) }
  let(:ansible_tower_manager) { FactoryBot.create(:automation_manager_ansible_tower) }
  let(:job_template) { FactoryBot.create(:ansible_configuration_script, :manager => ansible_tower_manager) }
  let(:service_ansible_tower) { FactoryBot.create(:service_ansible_tower, :job_template => job_template) }
  let(:task) { FactoryBot.create(:service_template_provision_task, :destination => service_ansible_tower, :miq_request => request) }
  let(:svc_task) { MiqAeMethodService::MiqAeServiceServiceTemplateProvisionTask.find(task.id) }
  let(:svc_service) { MiqAeMethodService::MiqAeServiceServiceAnsibleTower.find(service_ansible_tower.id) }
  let(:root_object) do
    Spec::Support::MiqAeMockObject.new('service'                         => svc_service,
                                       'service_template_provision_task' => task,
                                       'service_action'                  => 'Provision')
  end
  let(:ae_service) { Spec::Support::MiqAeMockService.new(root_object) }

  shared_examples_for "check_completed" do
    it "check" do
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

  context "retry ttl" do
    let(:service_ansible_tower) { FactoryBot.create(:service_ansible_tower, :job_template => job_template, :options => config_info_options) }
    let(:config_info_options) do
      {
        :config_info => {
          :provision  => {
            :execution_ttl => ttl
          },
          :retirement => {
            :execution_ttl => ttl
          }
        }
      }
    end
    shared_examples_for "#ttl" do
      it "check" do
        allow(svc_service).to receive(:check_completed).and_return([false, "retry"])

        described_class.new(ae_service).main
        expect(ae_service.root['ae_retry_interval']).to eq(ae_retry_interval)
      end
    end

    context "provision tests " do
      let(:root_object) do
        Spec::Support::MiqAeMockObject.new('service' => svc_service, 'service_action' => 'Provision', 'ae_state_max_retries' => 100)
      end

      context "650 ttl, 100 retries eq interval 6.5" do
        let(:ae_retry_interval) { 6.5.minutes }
        let(:ttl) { 650 }
        it_behaves_like "#ttl"
      end

      context "60 ttl, 100 retries interval 1.minute" do
        let(:ae_retry_interval) { 1.minute }
        let(:ttl) { 60 }
        it_behaves_like "#ttl"
      end

      context "0 ttl, 100 retries, interval 1.minute" do
        let(:ae_retry_interval) { 1.minute }
        let(:ttl) { 0 }
        it_behaves_like "#ttl"
      end
    end
    context "Retirement tests " do
      let(:root_object) do
        Spec::Support::MiqAeMockObject.new('service' => svc_service, 'service_action' => 'Retirement', 'ae_state_max_retries' => 100)
      end

      context "650 ttl, 100 retries eq interval 6.5" do
        let(:ae_retry_interval) { 6.5.minutes }
        let(:ttl) { 650 }
        it_behaves_like "#ttl"
      end

      context "60 ttl, 100 retries interval 1.minute" do
        let(:ae_retry_interval) { 1.minute }
        let(:ttl) { 60 }
        it_behaves_like "#ttl"
      end

      context "0 ttl, 100 retries, interval 1.minute" do
        let(:ae_retry_interval) { 1.minute }
        let(:ttl) { 0 }
        it_behaves_like "#ttl"
      end
    end

    context "Start 600 ttl, 50 retries eq interval 6" do
      let(:ae_retry_interval) { 12.minutes }
      let(:ttl) { 600 }
      let(:root_object) do
        Spec::Support::MiqAeMockObject.new('service' => svc_service, 'service_action' => 'Provision', 'ae_state_max_retries' => 50)
      end
      it_behaves_like "#ttl"
    end

    context "Start 600 ttl, 0 retries eq interval 1.minute" do
      let(:ae_retry_interval) { 1.minute }
      let(:ttl) { 600 }
      let(:root_object) do
        Spec::Support::MiqAeMockObject.new('service' => svc_service, 'service_action' => 'Provision', 'ae_state_max_retries' => 0)
      end
      it_behaves_like "#ttl"
    end
  end

  context "Log_and_raise" do
    let(:root_object) { Spec::Support::MiqAeMockObject.new('service' => svc_service, 'service_action' => 'Not_Provision') }
    it "Invalid service action " do
      allow(ManageIQ::Automate::System::CommonMethods::Utils::LogObject).to receive(:log_and_raise).with(/Invalid service_action/, ae_service).and_raise(RuntimeError)
      expect { described_class.new(ae_service).main }.to raise_error(RuntimeError)
    end
  end

  context "Log_and_raise" do
    let(:svc_service) { nil }
    it "Service not found" do
      allow(ManageIQ::Automate::System::CommonMethods::Utils::LogObject).to receive(:log_and_raise).with(/Service not found/, ae_service).and_raise(RuntimeError)
      expect { described_class.new(ae_service).main }.to raise_error(RuntimeError)
    end
  end
end
