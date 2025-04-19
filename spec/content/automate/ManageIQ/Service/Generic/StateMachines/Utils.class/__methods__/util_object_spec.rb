require_domain_file
require File.join(ManageIQ::Content::Engine.root, 'content/automate/ManageIQ/System/CommonMethods/Utils.class/__methods__/log_object.rb')

describe ManageIQ::Automate::Service::Generic::StateMachines::Utils::UtilObject do
  let(:admin) { FactoryBot.create(:user_admin) }
  let(:miq_server) { EvmSpecHelper.local_miq_server }
  let(:svc_model_miq_server) { MiqAeMethodService::MiqAeServiceMiqServer.find(miq_server.id) }
  let(:service_object) { FactoryBot.create(:service_terraform_template) }
  let(:miq_request) { FactoryBot.create(:service_template_provision_request, :requester => admin) }
  let(:request_type) { miq_request.request_type }
  let(:miq_task) { FactoryBot.create(:service_template_provision_task, :miq_request => miq_request) }
  let(:task) { MiqAeMethodService::MiqAeServiceServiceTemplateProvisionTask.find(miq_task.id) }
  let(:root_object) do
    Spec::Support::MiqAeMockObject.new(
      'request'                         => request_type,
      'service'                         => service_object,
      'service_action'                  => service_action,
      'service_template_provision_task' => task,
      'miq_server'                      => svc_model_miq_server
    )
  end
  let(:ae_service) { Spec::Support::MiqAeMockService.new(root_object) }
  let(:service_action) { 'Provision' }

  RSpec.shared_context 'provision_request_and_task_common' do
    let(:miq_request) { FactoryBot.create(:service_template_provision_request, :requester => admin) }
    let(:request_type) { miq_request.request_type }
    let(:miq_task) { FactoryBot.create(:service_template_provision_task, :miq_request => miq_request, :source => service_object) }
    let(:task) { MiqAeMethodService::MiqAeServiceServiceTemplateProvisionTask.find(miq_task.id) }
    let(:root_object) do
      Spec::Support::MiqAeMockObject.new(
        'request'                         => request_type,
        'service_template_provision_task' => task
      )
    end
    let(:ae_service) { Spec::Support::MiqAeMockService.new(root_object) }
  end

  RSpec.shared_context 'reconfigure_request_and_task_common' do
    let(:miq_request) { FactoryBot.create(:service_reconfigure_request, :requester => admin) }
    let(:request_type) { miq_request.request_type }
    let(:miq_task) { FactoryBot.create(:service_reconfigure_task, :miq_request => miq_request, :source => service_object) }
    let(:task) { MiqAeMethodService::MiqAeServiceServiceReconfigureTask.find(miq_task.id) }
    let(:root_object) do
      Spec::Support::MiqAeMockObject.new(
        'request'                  => request_type,
        'service_reconfigure_task' => task
      )
    end
    let(:ae_service) { Spec::Support::MiqAeMockService.new(root_object) }
  end

  RSpec.shared_context 'retirement_request_and_task_common' do
    let(:miq_request) { FactoryBot.create(:service_retire_request, :requester => admin) }
    let(:request_type) { miq_request.request_type }
    let(:miq_task) { FactoryBot.create(:service_retire_task, :miq_request => miq_request, :source => service_object) }
    let(:task) { MiqAeMethodService::MiqAeServiceServiceRetireTask.find(miq_task.id) }
    let(:root_object) do
      Spec::Support::MiqAeMockObject.new(
        'request'             => request_type,
        'service_retire_task' => task
      )
    end
    let(:ae_service) { Spec::Support::MiqAeMockService.new(root_object) }
  end

  describe "#service_task" do
    shared_examples_for "has request specific task" do
      it "gets service_task" do
        expect(ae_service.root[expected_task_name]).not_to be_nil

        service_task = described_class.service_task(ae_service)
        expect(service_task).to eq(ae_service.root[expected_task_name])
      end
    end

    context "has request with service_template_provision_task" do
      include_context 'provision_request_and_task_common'
      let(:expected_task_name) { "service_template_provision_task" }

      it_behaves_like "has request specific task"
    end

    context "has request with service_reconfigure_task" do
      include_context 'reconfigure_request_and_task_common'
      let(:expected_task_name) { "service_reconfigure_task" }

      it_behaves_like "has request specific task"
    end

    context "has request with service_retire_task" do
      include_context 'retirement_request_and_task_common'
      let(:expected_task_name) { "service_retire_task" }

      it_behaves_like "has request specific task"
    end
  end

  describe "#service_action" do
    shared_examples_for "when we have service_action" do
      it "get service_action" do
        service_action = described_class.service_action(ae_service)
        expect(service_action).not_to be_nil
        expect(service_action).to eq(expected_service_action)
      end
    end

    context "when attribute service_action is Provision" do
      let(:root_object) do
        Spec::Support::MiqAeMockObject.new(
          'service_action' => 'Provision'
        )
      end
      let(:expected_service_action) { 'Provision' }

      it_behaves_like "when we have service_action"
    end

    context "when attribute service_action is Reconfigure" do
      let(:root_object) do
        Spec::Support::MiqAeMockObject.new(
          'service_action' => 'Reconfigure'
        )
      end
      let(:expected_service_action) { 'Reconfigure' }

      it_behaves_like "when we have service_action"
    end

    context "when attribute service_action is Retirement" do
      let(:root_object) do
        Spec::Support::MiqAeMockObject.new(
          'service_action' => 'Retirement'
        )
      end
      let(:expected_service_action) { 'Retirement' }

      it_behaves_like "when we have service_action"
    end

    context "when request is service_reconfigure" do
      let(:root_object) do
        Spec::Support::MiqAeMockObject.new(
          'request' => 'service_reconfigure'
        )
      end
      it "service_action is Reconfigure" do
        expect(described_class.service_action(ae_service)).to eq('Reconfigure')
      end
    end

    context "Log_and_raise - Invalid service action" do
      let(:service_action) { 'Invalid-Action' }
      it "Invalid service action " do
        allow(ManageIQ::Automate::System::CommonMethods::Utils::LogObject).to receive(:log_and_raise).with(/Invalid service_action/, ae_service).and_raise(RuntimeError)

        expect { described_class.service_action(ae_service) }.to raise_error(RuntimeError)
      end
    end
  end

  describe "#service" do
    it "when service available" do
      expect(described_class.service(ae_service)).to eq(service_object)
    end

    context "when request is service_reconfigure, service_reconfigure_task is available and service not available" do
      include_context 'reconfigure_request_and_task_common'

      it "get service from service_reconfigure_task" do
        expect(described_class.service(ae_service).id).to eq(service_object.id)
      end
    end

    context "Log_and_raise - Service not found" do
      let(:service_object) { nil }
      it "Service not found" do
        allow(ManageIQ::Automate::System::CommonMethods::Utils::LogObject).to receive(:log_and_raise).with(/Service not found/, ae_service).and_raise(RuntimeError)

        expect { described_class.service(ae_service) }.to raise_error(RuntimeError)
      end
    end
  end

  describe "#update_task" do
    let(:msg) { 'executed successfully' }
    let(:status) { 'OK' }

    shared_examples_for "update_task passed with message and status" do
      it "update task" do
        described_class.update_task(msg, status, ae_service)

        expect(task.miq_request[:options][:user_message]).to eq(msg)
        expect(task.message).to eq(status)
      end
    end

    context "when service_template_provision_task is available" do
      include_context 'provision_request_and_task_common'

      it_behaves_like "update_task passed with message and status"
    end

    context "when service_reconfigure_task is available" do
      include_context 'reconfigure_request_and_task_common'

      it_behaves_like "update_task passed with message and status"
    end

    context "when service_retire_task is available" do
      include_context 'retirement_request_and_task_common'

      it_behaves_like "update_task passed with message and status"
    end
  end
end
