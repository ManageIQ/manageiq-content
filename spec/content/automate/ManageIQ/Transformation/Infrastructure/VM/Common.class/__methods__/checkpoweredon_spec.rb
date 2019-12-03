require_domain_file
require File.join(ManageIQ::Content::Engine.root, 'content/automate/ManageIQ/Transformation/Common.class/__methods__/utils.rb')

describe ManageIQ::Automate::Transformation::Infrastructure::VM::Common::CheckPoweredOn do
  let(:user) { FactoryBot.create(:user_with_email_and_group) }
  let(:group) { FactoryBot.create(:miq_group) }
  let(:vm) { FactoryBot.create(:vm) }
  let(:task) { FactoryBot.create(:service_template_transformation_plan_task) }

  let(:svc_model_user) { MiqAeMethodService::MiqAeServiceUser.find(user.id) }
  let(:svc_model_group) { MiqAeMethodService::MiqAeServiceMiqGroup.find(group.id) }
  let(:svc_model_vm) { MiqAeMethodService::MiqAeServiceVm.find(vm.id) }
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
    ManageIQ::Automate::Transformation::Infrastructure::VM::Common::CheckPoweredOn.instance_variable_set(:@task, nil)
    ManageIQ::Automate::Transformation::Infrastructure::VM::Common::CheckPoweredOn.instance_variable_set(:@vm, nil)
    allow(ManageIQ::Automate::Transformation::Common::Utils).to receive(:task).and_return(svc_model_task)
    allow(ManageIQ::Automate::Transformation::Common::Utils).to receive(:source_vm).and_return(svc_model_vm)
    allow(ManageIQ::Automate::Transformation::Common::Utils).to receive(:destination_vm).and_return(svc_model_vm)
    allow(svc_model_task).to receive(:get_option).with(:source_vm_power_state).and_return('on')
    allow(svc_model_vm).to receive(:power_state).and_return('off')
  end

  shared_examples_for "#main" do
    it "retries if VM is not powered on" do
      described_class.new(ae_service).main
      expect(ae_service.root['ae_result']).to eq('retry')
      expect(ae_service.root['ae_retry_interval']).to eq('15.seconds')
    end
  end

  describe "#main" do
    context "handling source vm" do
      before { ae_service.root['state_machine_phase'] = 'transformation' }
      it_behaves_like "#main"
    end

    context "handling destination vm" do
      before { ae_service.root['state_machine_phase'] = 'cleanup' }
      it_behaves_like "#main"
    end

    it "raises if task preflight check raises" do
      errormsg = 'Unexpected error'
      allow(svc_model_task).to receive(:get_option).with(:source_vm_power_state).and_raise(errormsg)
      expect { described_class.new(ae_service).main }.to raise_error(errormsg)
      expect(ae_service.get_state_var(:ae_state_progress)).to eq('message' => errormsg)
    end
  end
end
