require_domain_file
require File.join(ManageIQ::Content::Engine.root, 'content/automate/ManageIQ/Transformation/Common.class/__methods__/utils.rb')

describe ManageIQ::Automate::Transformation::Ansible::LaunchPlaybookAsAService do
  let(:user) { FactoryBot.create(:user_with_email_and_group) }
  let(:group) { FactoryBot.create(:miq_group) }
  let(:ems_vmware) { FactoryBot.create(:ems_vmware) }
  let(:ems_redhat) { FactoryBot.create(:ems_redhat) }
  let(:src_cluster_vmware) { FactoryBot.create(:ems_cluster, :ext_management_system => ems_vmware) }
  let(:dst_cluster_redhat) { FactoryBot.create(:ems_cluster, :ext_management_system => ems_redhat) }

  let(:src_lan) { FactoryBot.create(:lan) }
  let(:src_nic) { FactoryBot.create(:guest_device_nic, :lan => src_lan, :network => src_network) }
  let(:src_network) { FactoryBot.create(:network, :ipaddress => '10.0.0.1') }
  let(:src_hardware) { FactoryBot.create(:hardware, :nics => [src_nic], :networks => [src_network]) }

  let(:src_vm_vmware) { FactoryBot.create(:vm_vmware, :ext_management_system => ems_vmware, :ems_cluster => src_cluster_vmware, :hardware => src_hardware) }
  let(:dst_vm_redhat) { FactoryBot.create(:vm_redhat, :ext_management_system => ems_redhat, :ems_cluster => dst_cluster_redhat) }

  let(:credential) { FactoryBot.create(:ansible_machine_credential) }
  let(:ansible_playbook_pre_catalog_item_options) do
    {
      :name        => 'Pre-migration playbook',
      :description => 'Pre-migration playbook',
      :config_info => {
        :provision => {
          :credential_id => credential.id
        }
      }
    }
  end

  let(:ansible_playbook_post_catalog_item_options) do
    {
      :name        => 'Post-migration playbook',
      :description => 'Post-migration playbook',
      :config_info => {
        :provision => {
          :credential_id => credential.id
        }
      }
    }
  end

  let(:service_template_ansible_playbook_pre) { ServiceTemplateAnsiblePlaybook.create_catalog_item(ansible_playbook_pre_catalog_item_options, user) }
  let(:service_template_ansible_playbook_post) { ServiceTemplateAnsiblePlaybook.create_catalog_item(ansible_playbook_post_catalog_item_options, user) }
  let(:ansible_playbook_pre_service_request) { FactoryBot.create(:service_template_provision_request, :source => service_template_ansible_playbook_pre) }

  let(:mapping) do
    FactoryBot.create(
      :transformation_mapping,
      :transformation_mapping_items => [
        FactoryBot.create(:transformation_mapping_item, :source => src_cluster_vmware, :destination => dst_cluster_redhat)
      ]
    )
  end

  let(:plan_catalog_item_options) do
    {
      :name        => 'Transformation Plan',
      :description => 'a description',
      :config_info => {
        :transformation_mapping_id => mapping.id,
        :pre_service_id            => service_template_ansible_playbook_pre.id,
        :post_service_id           => service_template_ansible_playbook_post.id,
        :actions                   => [
          {:vm_id => src_vm_vmware.id.to_s, :pre_service => true, :post_service => true}
        ],
      }
    }
  end

  let(:transformation_plan) { ServiceTemplateTransformationPlan.create_catalog_item(plan_catalog_item_options) }
  let(:transformation_plan_request) { FactoryBot.create(:service_template_transformation_plan_request, :source => transformation_plan) }
  let(:transformation_plan_task) { FactoryBot.create(:service_template_transformation_plan_task, :source => src_vm_vmware, :miq_request => transformation_plan_request) }

  let(:svc_model_user) { MiqAeMethodService::MiqAeServiceUser.find(user.id) }
  let(:svc_model_group) { MiqAeMethodService::MiqAeServiceMiqGroup.find(group.id) }
  let(:svc_model_src_nic) { MiqAeMethodService::MiqAeServiceGuestDevice.find(src_nic.id) }
  let(:svc_model_src_network) { MiqAeMethodService::MiqAeServiceNetwork.find(src_network.id) }
  let(:svc_model_src_vm_vmware) { MiqAeMethodService::MiqAeServiceManageIQ_Providers_Vmware_InfraManager_Vm.find(src_vm_vmware.id) }
  let(:svc_model_dst_vm_redhat) { MiqAeMethodService::MiqAeServiceManageIQ_Providers_Redhat_InfraManager_Vm.find(dst_vm_redhat.id) }
  let(:svc_model_transformation_plan_task) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask.find(transformation_plan_task.id) }
  let(:svc_model_service_template_ansible_playbook_pre) { MiqAeMethodService::MiqAeServiceServiceTemplateAnsiblePlaybook.find(service_template_ansible_playbook_pre.id) }
  let(:svc_model_ansible_playbook_pre_service_request) { MiqAeMethodService::MiqAeServiceServiceTemplateProvisionRequest.find(ansible_playbook_pre_service_request.id) }

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
    allow(ManageIQ::Automate::Transformation::Common::Utils).to receive(:task).and_return(svc_model_transformation_plan_task)
    allow(ManageIQ::Automate::Transformation::Common::Utils).to receive(:source_vm).and_return(svc_model_src_vm_vmware)
    allow(ManageIQ::Automate::Transformation::Common::Utils).to receive(:destination_vm).and_return(svc_model_dst_vm_redhat)
    allow(ae_service).to receive(:inputs).and_return('transformation_hook' => 'pre')
    allow(ae_service).to receive(:execute).and_return(svc_model_ansible_playbook_pre_service_request)
    allow(svc_model_src_vm_vmware).to receive(:refresh).with(no_args).and_return(nil)
    svc_model_transformation_plan_task.set_option(:destination_vm_id, dst_vm_redhat.id)
  end

  describe "target_host" do
    it "returns source vm for pre migration" do
      expect(described_class.new(ae_service).target_host.id).to eq(svc_model_src_vm_vmware.id)
    end

    it "returns destination vm for post migration" do
      allow(ae_service).to receive(:inputs).and_return('transformation_hook' => 'post')
      expect(described_class.new(ae_service).target_host.id).to eq(svc_model_dst_vm_redhat.id)
    end
  end

  describe "main" do
    it "retries if target vm has no ip address" do
      src_hardware.networks = []
      described_class.new(ae_service).main
      expect(ae_service.root['ae_result']).to eq('retry')
    end

    it "creates a service provision request and store the request id in task" do
      service_dialog_options = {
        :credential => credential.id,
        :hosts      => "10.0.0.1"
      }
      expect(ae_service).to receive(:execute).with(:create_service_provision_request, svc_model_service_template_ansible_playbook_pre, service_dialog_options)
      described_class.new(ae_service).main
      expect(svc_model_transformation_plan_task.options[:pre_ansible_playbook_service_request_id]).to eq(svc_model_ansible_playbook_pre_service_request.id)
    end
  end
end
