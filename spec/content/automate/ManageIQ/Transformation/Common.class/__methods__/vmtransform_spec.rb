require_domain_file
require File.join(ManageIQ::Content::Engine.root, 'content/automate/ManageIQ/Transformation/Common.class/__methods__/utils.rb')

describe ManageIQ::Automate::Transformation::Common::VMTransform do
  let(:user) { FactoryGirl.create(:user_with_email_and_group) }
  let(:group) { FactoryGirl.create(:miq_group) }
  let(:task) { FactoryGirl.create(:service_template_transformation_plan_task) }

  let(:svc_model_user) { MiqAeMethodService::MiqAeServiceUser.find(user.id) }
  let(:svc_model_group) { MiqAeMethodService::MiqAeServiceMiqGroup.find(group.id) }
  let(:svc_model_task) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask.find(task.id) }

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

  it "returns 'active' if run_conversion succeeds " do
    allow(svc_model_task).to receive(:run_conversion).and_return('active')
    expect(described_class.new(ae_service).main).to eq('active')
  end

  it "raises if run_conversion fails" do
    errormsg = 'Unexpected error'
    allow(svc_model_task).to receive(:run_conversion).and_raise(errormsg)
    expect { described_class.new(ae_service).main }.to raise_error(errormsg)
    expect(ae_service.get_state_var(:ae_state_progress)).to eq('message' => errormsg)
  end
end
