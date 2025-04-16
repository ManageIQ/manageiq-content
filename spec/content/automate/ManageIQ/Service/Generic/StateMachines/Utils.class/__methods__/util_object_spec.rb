require_domain_file
require File.join(ManageIQ::Content::Engine.root, 'content/automate/ManageIQ/System/CommonMethods/Utils.class/__methods__/log_object.rb')

describe ManageIQ::Automate::Service::Generic::StateMachines::Utils::UtilObject do
  let(:admin) { FactoryBot.create(:user_admin) }
  let(:miq_request) { FactoryBot.create(:service_template_provision_request, :request_type => request_type, :requester => admin) }
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
  let(:miq_server) { EvmSpecHelper.local_miq_server }
  let(:svc_model_miq_server) { MiqAeMethodService::MiqAeServiceMiqServer.find(miq_server.id) }
  let(:service_object) { FactoryBot.create(:service_terraform_template) }
  let(:request_type) { 'clone_to_service' }
  let(:service_action) { 'Provision' }

  describe "#service_action" do
    shared_examples_for "when we have service_action" do
      it "get service_action" do
        expect(ManageIQ::Automate::Service::Generic::StateMachines::Utils::UtilObject.service_action(ae_service)).to eq(service_action)
      end
    end

    context "service_action is Provision" do
      it_behaves_like "when we have service_action"
    end

    context "service_action is Reconfigure" do
      let(:service_action) { 'Reconfigure' }
      it_behaves_like "when we have service_action"
    end

    context "service_action is Retirement" do
      let(:service_action) { 'Retirement' }
      it_behaves_like "when we have service_action"
    end

    context "when request is service_reconfigure" do
      let(:root_object) { Spec::Support::MiqAeMockObject.new('request' => 'service_reconfigure') }
      it "service_action is Reconfigure" do
        expect(ManageIQ::Automate::Service::Generic::StateMachines::Utils::UtilObject.service_action(ae_service)).to eq('Reconfigure')
      end
    end

    context "Log_and_raise - Invalid service action" do
      let(:service_action) { 'Invalid-Action' }
      it "Invalid service action " do
        allow(ManageIQ::Automate::System::CommonMethods::Utils::LogObject).to receive(:log_and_raise).with(/Invalid service_action/, ae_service).and_raise(RuntimeError)

        expect { ManageIQ::Automate::Service::Generic::StateMachines::Utils::UtilObject.service_action(ae_service) }.to raise_error(RuntimeError)
      end
    end
  end

  describe "#service" do
    it "when service available" do
      expect(ManageIQ::Automate::Service::Generic::StateMachines::Utils::UtilObject.service(ae_service)).to eq(service_object)
    end

    context "when request is service_reconfigure, service_reconfigure_task is available and service not available" do
      let(:request_type) { 'service_reconfigure' }
      let(:miq_request) { FactoryBot.create(:service_reconfigure_request, :requester => admin) }
      let(:miq_task) { FactoryBot.create(:service_reconfigure_task, :request_type => request_type, :miq_request => miq_request, :source => service_object) }
      let(:task) { MiqAeMethodService::MiqAeServiceServiceReconfigureTask.find(miq_task.id) }
      let(:root_object) do
        Spec::Support::MiqAeMockObject.new(
          'request'                  => request_type,
          'service_reconfigure_task' => task
        )
      end
      let(:ae_service) { Spec::Support::MiqAeMockService.new(root_object) }

      it "get service from service_reconfigure_task" do
        expect(ManageIQ::Automate::Service::Generic::StateMachines::Utils::UtilObject.service(ae_service).id).to eq(service_object.id)
      end
    end

    context "Log_and_raise - Service not found" do
      let(:service_object) { nil }
      it "Service not found" do
        allow(ManageIQ::Automate::System::CommonMethods::Utils::LogObject).to receive(:log_and_raise).with(/Service not found/, ae_service).and_raise(RuntimeError)

        expect { ManageIQ::Automate::Service::Generic::StateMachines::Utils::UtilObject.service(ae_service) }.to raise_error(RuntimeError)
      end
    end
  end

  describe "#update_task" do
    let(:msg) { 'executed successfully' }
    let(:status) { 'OK' }

    shared_examples_for "update_task passed with message and status" do
      it "update task" do
        ManageIQ::Automate::Service::Generic::StateMachines::Utils::UtilObject.update_task(msg, status, ae_service)

        # TODO: Fix NoMethodError: undefined method `user_message' for an instance of MiqAeMethodService::MiqAeServiceServiceTemplateProvisionRequest
        # expect(task.miq_request.user_message).to eq(msg)

        expect(task.message).to eq(status)
      end
    end

    context "when service_template_provision_task is available" do
      it_behaves_like "update_task passed with message and status"
    end

    context "when service_reconfigure_task is available" do
      let(:request_type) { 'service_reconfigure' }
      let(:miq_request) { FactoryBot.create(:service_reconfigure_request, :requester => admin) }
      let(:miq_task) { FactoryBot.create(:service_reconfigure_task, :request_type => request_type, :miq_request => miq_request, :source => service_object) }
      let(:task) { MiqAeMethodService::MiqAeServiceServiceReconfigureTask.find(miq_task.id) }
      let(:root_object) do
        Spec::Support::MiqAeMockObject.new(
          'request'                  => request_type,
          'service_reconfigure_task' => task
        )
      end
      let(:ae_service) { Spec::Support::MiqAeMockService.new(root_object) }

      it_behaves_like "update_task passed with message and status"
    end

    # TODO: fix this
    xcontext "when service_retire_task is available" do
      let(:request_type) { 'service_retire' }
      let(:miq_request) { FactoryBot.create(:service_retire_request, :requester => admin) }
      let(:miq_task) { FactoryBot.create(:service_retire_task, :request_type => request_type, :miq_request => miq_request, :source => service_object) }
      let(:task) { MiqAeMethodService::MiqAeServiceServiceReconfigureTask.find(miq_task.id) }
      let(:root_object) do
        Spec::Support::MiqAeMockObject.new(
          'request'             => request_type,
          'service_retire_task' => task
        )
      end
      let(:ae_service) { Spec::Support::MiqAeMockService.new(root_object) }

      it_behaves_like "update_task passed with message and status"
    end
  end
end
