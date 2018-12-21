require_domain_file
require File.join(ManageIQ::Content::Engine.root, 'content/automate/ManageIQ/Transformation/Common.class/__methods__/utils.rb')

describe ManageIQ::Automate::Transformation::Infrastructure::VM::Common::CheckVmInInventory do
  let(:user) { FactoryBot.create(:user_with_email_and_group) }
  let(:src_vm_vmware) { FactoryBot.create(:vm_vmware, :ext_management_system => src_ems, :ems_cluster => src_cluster) }
  let(:dst_vm_redhat) { FactoryBot.create(:vm_redhat, :ext_management_system => dst_ems) }
  let(:dst_vm_openstack) { FactoryBot.create(:vm_openstack, :ext_management_system => dst_ems) }
  let(:src_ems) { FactoryBot.create(:ext_management_system) }
  let(:src_cluster) { FactoryBot.create(:ems_cluster, :ext_management_system => src_ems) }
  let(:dst_ems) { FactoryBot.create(:ext_management_system) }
  let(:dst_cluster) { FactoryBot.create(:ems_cluster, :ext_management_system => dst_ems) }

  let(:mapping) do
    FactoryBot.create(
      :transformation_mapping,
      :transformation_mapping_items => [
        FactoryBot.create(:transformation_mapping_item, :source => src_cluster, :destination => dst_cluster)
      ]
    )
  end

  let(:catalog_item_options) do
    {
      :name        => 'Transformation Plan',
      :description => 'a description',
      :config_info => {
        :transformation_mapping_id => mapping.id,
        :actions                   => [
          {:vm_id => src_vm.id.to_s, :pre_service => false, :post_service => false}
        ],
      }
    }
  end

  let(:plan) { ServiceTemplateTransformationPlan.create_catalog_item(catalog_item_options) }
  let(:request) { FactoryBot.create(:service_template_transformation_plan_request, :source => plan) }
  let(:task) { FactoryBot.create(:service_template_transformation_plan_task, :miq_request => request, :request_type => 'transformation_plan', :source => src_vm_vmware) }

  let(:svc_model_user) { MiqAeMethodService::MiqAeServiceUser.find(user.id) }
  let(:svc_model_task) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask.find(task.id) }
  let(:svc_model_src_vm_vmware) { MiqAeMethodService::MiqAeServiceManageIQ_Providers_Vmware_InfraManager_Vm.find(src_vm_vmware.id) }
  let(:svc_model_dst_vm_redhat) { MiqAeMethodService::MiqAeServiceManageIQ_Providers_Redhat_InfraManager_Vm.find(dst_vm_redhat.id) }
  let(:svc_model_dst_vm_openstack) { MiqAeMethodService::MiqAeServiceManageIQ_Providers_Openstack_CloudManager_Vm.find(dst_vm_openstack.id) }
  let(:svc_model_src_cluster) { MiqAeMethodService::MiqAeServiceEmsCluster.find(src_cluster.id) }
  let(:svc_model_dst_cluster) { MiqAeMethodService::MiqAeServiceEmsCluster.find(dst_cluster.id) }
  let(:svc_model_dst_ems) { MiqAeMethodService::MiqAeServiceExtManagementSystem.find(dst_ems.id) }

  let(:root) do
    Spec::Support::MiqAeMockObject.new(
      'current' => current_object,
      'user'    => svc_model_user,
      'state_machine_phase' => 'transformation'
    )
  end

  let(:current_object) { Spec::Support::MiqAeMockObject.new }
  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root).tap do |service|
      current_object.parent = root
      service.current_object = current_object
    end
  end

  let(:svc_vmdb_handle) { MiqAeMethodService::MiqAeServiceVm }

  before do
    ManageIQ::Automate::Transformation::Infrastructure::VM::Common::CheckVmInInventory.instance_variable_set(:@task, nil)
    ManageIQ::Automate::Transformation::Infrastructure::VM::Common::CheckVmInInventory.instance_variable_set(:@source_vm, nil)

    allow(ManageIQ::Automate::Transformation::Common::Utils).to receive(:task).and_return(svc_model_task)
    allow(ae_service).to receive(:vmdb).with(:vm).and_return(svc_vmdb_handle)
  end

  shared_examples_for "#main" do
    before do
      allow(ManageIQ::Automate::Transformation::Common::Utils).to receive(:source_vm).and_return(svc_model_src_vm)
    end

    it "retries if destination_vm is nil" do
      allow(svc_vmdb_handle).to receive(:find_by).with(:name => svc_model_src_vm.name, :ems_id => svc_model_dst_ems.id).and_return(nil)
      described_class.new(ae_service).main
      expect(ae_service.root['ae_result']).to eq('retry')
      expect(ae_service.root['ae_retry_interval']).to eq('15.seconds')
    end

    it "sets task options if destination_vm exists" do
      allow(svc_vmdb_handle).to receive(:find_by).with(:name => svc_model_src_vm.name, :ems_id => svc_model_dst_ems.id).and_return(svc_model_dst_vm)
      described_class.new(ae_service).main
      expect(svc_model_task.get_option(:destination_vm_id)).to eq(svc_model_dst_vm.id)
    end

    it "raises if VMDB find raises" do
      allow(svc_vmdb_handle).to receive(:find_by).with(:name => svc_model_src_vm.name, :ems_id => svc_model_dst_ems.id).and_raise('Unexpected error')
      expect { described_class.new(ae_service).main }.to raise_error('Unexpected error')
      expect(ae_service.get_state_var(:ae_state_progress)).to eq('message' => 'Unexpected error')
    end
  end

  context "validate when source is vmware and destination redhat" do
    let(:src_vm) { src_vm_vmware }
    let(:dst_vm) { dst_vm_redhat }
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    let(:svc_model_dst_vm) { svc_model_dst_vm_redhat }

    it_behaves_like "#main"
  end

  context "validate when source is vmware and destination openstack" do
    let(:src_vm) { src_vm_vmware }
    let(:dst_vm) { dst_vm_openstack }
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    let(:svc_model_dst_vm) { svc_model_dst_vm_openstack }

    it_behaves_like "#main"
  end
end
