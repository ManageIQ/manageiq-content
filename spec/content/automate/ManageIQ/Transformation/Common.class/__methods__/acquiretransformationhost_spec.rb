require_domain_file
require File.join(ManageIQ::Content::Engine.root, 'content/automate/ManageIQ/Transformation/Common.class/__methods__/utils.rb')

describe ManageIQ::Automate::Transformation::Common::AcquireTransformationHost do
  let(:user) { FactoryGirl.create(:user_with_email_and_group) }
  let(:task) { FactoryGirl.create(:service_template_transformation_plan_task) }
  let(:host) { FactoryGirl.create(:host) }

  let(:svc_model_user) { MiqAeMethodService::MiqAeServiceUser.find(user.id) }
  let(:svc_model_task) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask.find(task.id) }
  let(:svc_model_host) { MiqAeMethodService::MiqAeServiceHost.find(host.id) }

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
    it "without transformation host" do
      allow(svc_model_task).to receive(:get_option).with(:transformation_host_id).and_return(nil)
      described_class.new(ae_service).main
      expect(ae_service.root['ae_result']).to eq('retry')
      expect(ae_service.root['ae_retry_server_affinity']).to eq(true)
      expect(ae_service.root['ae_retry_interval']).to eq(15.seconds)
    end

    it "with transformation host" do
      allow(svc_model_task).to receive(:get_option).with(:transformation_host_id).and_return(svc_model_host.id)
      described_class.new(ae_service).main
      expect(ae_service.root['ae_result']).to be_nil
      expect(ae_service.root['ae_retry_server_affinity']).to be_nil
      expect(ae_service.root['ae_retry_interval']).to be_nil
    end
  end

  context "catchall exception rescue" do
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }

    before do
      allow(svc_model_task).to receive(:get_option).with(:transformation_host_id).and_raise(StandardError, 'kaboom')
    end

    it "forcefully raise" do
      expect { described_class.new(ae_service).main }.to raise_error('kaboom')
      expect(ae_service.get_state_var(:ae_state_progress)).to eq('message' => 'kaboom')
    end
  end
end
