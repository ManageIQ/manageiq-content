require_domain_file
require File.join(ManageIQ::Content::Engine.root, 'content/automate/ManageIQ/Transformation/Common.class/__methods__/utils.rb')

describe ManageIQ::Automate::Transformation::Infrastructure::VM::Common::ApplyRightSize do
  let(:user) { FactoryGirl.create(:user_with_email_and_group) }
  let(:group) { FactoryGirl.create(:miq_group) }
  let(:task) { FactoryGirl.create(:service_template_transformation_plan_task) }
  let(:src_vm_vmware) { FactoryGirl.create(:vm_vmware) }
  let(:dst_vm_redhat) { FactoryGirl.create(:vm_redhat) }
  let(:dst_ems_redhat) { FactoryGirl.create(:ems_redhat) }

  let(:svc_model_user) { MiqAeMethodService::MiqAeServiceUser.find(user.id) }
  let(:svc_model_group) { MiqAeMethodService::MiqAeServiceMiqGroup.find(group.id) }
  let(:svc_model_task) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask.find(task.id) }
  let(:svc_model_src_vm_vmware) { MiqAeMethodService::MiqAeServiceManageIQ_Providers_Vmware_InfraManager_Vm.find(src_vm_vmware.id) }
  let(:svc_model_dst_vm_redhat) { MiqAeMethodService::MiqAeServiceManageIQ_Providers_Redhat_InfraManager_Vm.find(dst_vm_redhat.id) }
  let(:svc_model_dst_ems_redhat) { MiqAeMethodService::MiqAeServiceExtManagementSystem.find(dst_ems_redhat.id) }

  let(:root) do
    Spec::Support::MiqAeMockObject.new(
      'current'                                   => current_object,
      'user'                                      => svc_model_user,
      'service_template_transformation_plan_task' => svc_model_task
    )
  end

  let(:current_object) { Spec::Support::MiqAeMockObject.new }
  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root).tap do |service|
      current_object.parent = root
      service.current_object = current_object
    end
  end

  before do
    allow(ManageIQ::Automate::Transformation::Common::Utils).to receive(:task).and_return(svc_model_task)
    allow(ManageIQ::Automate::Transformation::Common::Utils).to receive(:source_vm).and_return(svc_model_src_vm)
    allow(ManageIQ::Automate::Transformation::Common::Utils).to receive(:destination_vm).and_return(svc_model_dst_vm)

    allow(svc_model_src_vm).to receive(:aggressive_recommended_vcpus).and_return(1)
    allow(svc_model_src_vm).to receive(:conservative_recommended_mem).and_return(1024)
    allow(svc_model_dst_vm).to receive(:set_number_of_cpus)
    allow(svc_model_dst_vm).to receive(:set_memory)
  end

  shared_examples_for "apply right size" do
    it "#apply_right_size_cpu" do
      allow(svc_model_task).to receive(:get_option).with(:right_size_strategy_cpu).and_return('aggressive')
      expect(svc_model_dst_vm).to receive(:set_number_of_cpus).with(1, :sync => true)
      described_class.new(ae_service).apply_right_size_cpu('aggressive')
    end

    it "#apply_right_size_memory" do
      allow(svc_model_task).to receive(:get_option).with(:right_size_strategy_memory).and_return('conservative')
      expect(svc_model_dst_vm).to receive(:set_memory).with(1024, :sync => true)
      described_class.new(ae_service).apply_right_size_memory('conservative')
    end

    it "#main without strategies" do
      expect(svc_model_dst_vm).not_to receive(:set_number_of_cpus)
      expect(svc_model_dst_vm).not_to receive(:set_memory)
      described_class.new(ae_service).main
    end

    it "# main with strategies" do
      allow(svc_model_task).to receive(:get_option).with(:right_size_strategy_cpu).and_return('aggressive')
      allow(svc_model_task).to receive(:get_option).with(:right_size_strategy_memory).and_return('conservative')
      expect(svc_model_dst_vm).to receive(:set_number_of_cpus).with(1, :sync => true)
      expect(svc_model_dst_vm).to receive(:set_memory).with(1024, :sync => true)
      described_class.new(ae_service).main
    end
  end

  context "apply_right_size_cpu with source vmware and destination redhat" do
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    let(:svc_model_dst_vm) { svc_model_dst_vm_redhat }

    it_behaves_like "apply right size"
  end

  context "catchall exception rescue" do
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    let(:svc_model_dst_vm) { svc_model_dst_vm_redhat }
    let(:svc_model_dst_ems) { svc_model_dst_ems_redhat }

    before do
      allow(svc_model_task).to receive(:get_option).with(:right_size_strategy_cpu).and_raise(StandardError, 'kaboom')
    end

    it "forcefully raise" do
      expect { described_class.new(ae_service).main }.to raise_error('kaboom')
      expect(ae_service.get_state_var(:ae_state_progress)).to eq('message' => 'kaboom')
    end
  end
end
