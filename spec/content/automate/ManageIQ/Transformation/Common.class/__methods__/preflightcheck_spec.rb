require_domain_file
require File.join(ManageIQ::Content::Engine.root, 'content/automate/ManageIQ/Transformation/Common.class/__methods__/utils.rb')

describe ManageIQ::Automate::Transformation::Common::PreflightCheck do
  let(:user) { FactoryBot.create(:user_with_email_and_group) }
  let(:task) { FactoryBot.create(:service_template_transformation_plan_task) }
  let(:vm) { FactoryBot.create(:vm_openstack) }
  let(:conversion_host) { FactoryBot.create(:conversion_host, :resource => vm) }

  let(:svc_model_user) { MiqAeMethodService::MiqAeServiceUser.find(user.id) }
  let(:svc_model_task) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask.find(task.id) }
  let(:svc_model_conversion_host) { MiqAeMethodService::MiqAeServiceConversionHost.find(conversion_host.id) }

  let(:root) do
    Spec::Support::MiqAeMockObject.new(
      'current'             => current_object,
      'user'                => svc_model_user,
      'state_machine_phase' => 'transformation'
    )
  end

  let(:current_object) { Spec::Support::MiqAeMockObject.new }
  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root
      service.object = current_object
    end
  end

  before do
    allow(ManageIQ::Automate::Transformation::Common::Utils).to receive(:task).and_return(svc_model_task)
  end

  context "#main" do
    it "retries when preflight check not done" do
      allow(svc_model_task).to receive(:state).and_return('active')
      described_class.new(ae_service).main
      expect(ae_service.root['ae_result']).to eq('retry')
      expect(ae_service.root['ae_retry_server_affinity']).to eq(true)
      expect(ae_service.root['ae_retry_interval']).to eq(15.seconds)
    end

    it "stops retrying when preflight check passed" do
      allow(svc_model_task).to receive(:state).and_return('migrate')
      described_class.new(ae_service).main
      expect(ae_service.root['ae_result']).to be_nil
      expect(ae_service.root['ae_retry_server_affinity']).to be_nil
      expect(ae_service.root['ae_retry_interval']).to be_nil
    end
  end
end
