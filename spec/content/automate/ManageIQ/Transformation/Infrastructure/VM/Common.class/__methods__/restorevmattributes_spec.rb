require_domain_file
require File.join(ManageIQ::Content::Engine.root, 'content/automate/ManageIQ/Transformation/Common.class/__methods__/utils.rb')

describe ManageIQ::Automate::Transformation::Infrastructure::VM::Common::RestoreVmAttributes do
  let(:user) { FactoryGirl.create(:user_with_email_and_group) }
  let(:group) { FactoryGirl.create(:miq_group) }
  let(:task) { FactoryGirl.create(:service_template_transformation_plan_task) }
  let(:src_vm_vmware) { FactoryGirl.create(:vm_vmware) }
  let(:dst_vm_redhat) { FactoryGirl.create(:vm_redhat) }
  let(:dst_vm_openstack) { FactoryGirl.create(:vm_openstack) }
  let(:service) { FactoryGirl.create(:service) }
  let!(:parent_classification) { FactoryGirl.create(:classification, :name => "environment", :description => "Environment") }
  let!(:classification) { FactoryGirl.create(:classification, :name => "prod", :description => "Production", :parent => parent_classification) }

  let(:svc_model_user) { MiqAeMethodService::MiqAeServiceUser.find(user.id) }
  let(:svc_model_group) { MiqAeMethodService::MiqAeServiceMiqGroup.find(group.id) }
  let(:svc_model_task) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask.find(task.id) }
  let(:svc_model_src_vm_vmware) { MiqAeMethodService::MiqAeServiceManageIQ_Providers_Vmware_InfraManager_Vm.find(src_vm_vmware.id) }
  let(:svc_model_dst_vm_redhat) { MiqAeMethodService::MiqAeServiceManageIQ_Providers_Redhat_InfraManager_Vm.find(dst_vm_redhat.id) }
  let(:svc_model_dst_vm_openstack) { MiqAeMethodService::MiqAeServiceManageIQ_Providers_Openstack_CloudManager_Vm.find(dst_vm_openstack.id) }
  let(:svc_model_service) { MiqAeMethodService::MiqAeServiceService.find(service.id) }

  let(:retirement_date) { Time.now.utc + 1.day }

  let(:root) do
    Spec::Support::MiqAeMockObject.new(
      'current' => current_object,
      'user'    => svc_model_user,
    )
  end

  let(:current_object) { Spec::Support::MiqAeMockObject.new }
  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root).tap do |service|
      current_object.parent = root
      service.current_object = current_object
    end
  end

  def set_vm_identity
    svc_model_src_vm.add_to_service(svc_model_service)
    src_vm.tag_with("prod", :ns => "/managed", :cat => "environment")
    svc_model_src_vm.custom_set('attr', 'value')
    svc_model_src_vm.owner = svc_model_user
    svc_model_src_vm.group = svc_model_group
    svc_model_src_vm.retires_on = retirement_date
    svc_model_src_vm.retirement_warn = 7
  end

  shared_examples_for "restore identity" do
    let(:svc_vmdb_handle) { MiqAeMethodService::MiqAeServiceMiqGroup }

    before do
      allow(ManageIQ::Automate::Transformation::Common::Utils).to receive(:task).and_return(svc_model_task)
      allow(ManageIQ::Automate::Transformation::Common::Utils).to receive(:source_vm).and_return(svc_model_src_vm)
      allow(ManageIQ::Automate::Transformation::Common::Utils).to receive(:destination_vm).and_return(svc_model_dst_vm)
      set_vm_identity
    end

    it "restore service" do
      described_class.new(ae_service).vm_restore_service
      expect(svc_model_src_vm.service).to be_nil
      expect(svc_model_dst_vm.service.id).to eq(svc_model_service.id)
    end

    it "restore tags" do
      described_class.new(ae_service).vm_restore_tags
      expect(svc_model_dst_vm.tags).to eq(["environment/prod"])
    end

    it "restore customer attributes" do
      described_class.new(ae_service).vm_restore_custom_attributes
      expect(svc_model_dst_vm.custom_get('attr')).to eq('value')
    end

    it "restore ownership" do
      allow(ae_service).to receive(:vmdb).with(:miq_group).and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:find_by).with(:id => svc_model_group.id).and_return(svc_model_group)
      described_class.new(ae_service).vm_restore_ownership
      expect(svc_model_dst_vm.owner.id).to eq(svc_model_user.id)
      expect(svc_model_dst_vm.miq_group_id).to eq(svc_model_group.id)
    end

    it "restore retirement" do
      described_class.new(ae_service).vm_restore_retirement
      expect(svc_model_dst_vm.retires_on.to_i).to be(retirement_date.to_i)
      expect(svc_model_dst_vm.retirement_warn).to eq(7)
    end

    it "restore identity" do
      allow(ae_service).to receive(:vmdb).with(:miq_group).and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:find_by).with(:id => svc_model_group.id).and_return(svc_model_group)
      described_class.new(ae_service).main
      expect(svc_model_src_vm.service).to be_nil
      expect(svc_model_dst_vm.service.id).to eq(svc_model_service.id)
      expect(svc_model_dst_vm.tags).to eq(["environment/prod"])
      expect(svc_model_dst_vm.custom_get('attr')).to eq('value')
      expect(svc_model_dst_vm.owner.id).to eq(svc_model_user.id)
      expect(svc_model_dst_vm.miq_group_id).to eq(svc_model_group.id)
      expect(svc_model_dst_vm.retires_on.to_i).to be(retirement_date.to_i)
      expect(svc_model_dst_vm.retirement_warn).to eq(7)
    end

    it "forcefully raise" do
      allow(svc_model_src_vm).to receive(:service).and_raise('Unexpected error')
      expect { described_class.new(ae_service).main }.to raise_error('Unexpected error')
      expect(ae_service.get_state_var(:ae_state_progress)).to eq('message' => 'Unexpected error')
    end
  end

  context "restore when source is vmware and destination redhat" do
    let(:src_vm) { src_vm_vmware }
    let(:dst_vm) { dst_vm_redhat }
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    let(:svc_model_dst_vm) { svc_model_dst_vm_redhat }

    it_behaves_like "restore identity"
  end

  context "restore when source is vmware and destination openstack" do
    let(:src_vm) { src_vm_vmware }
    let(:dst_vm) { dst_vm_openstack }
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    let(:svc_model_dst_vm) { svc_model_dst_vm_openstack }

    it_behaves_like "restore identity"
  end
end
