require_domain_file
require File.join(ManageIQ::Content::Engine.root, 'content/automate/ManageIQ/Transformation/Common.class/__methods__/utils.rb')

describe ManageIQ::Automate::Transformation::Common::AssessTransformation do
  let(:user) { FactoryBot.create(:user_with_email_and_group) }
  let(:group) { FactoryBot.create(:miq_group) }
  let(:task) { FactoryBot.create(:service_template_transformation_plan_task) }
  let(:src_ems_vmware) { FactoryBot.create(:ems_vmware) }
  let(:src_cluster_vmware) { FactoryBot.create(:ems_cluster, :ext_management_system => src_ems_vmware) }
  let(:src_vm_vmware) { FactoryBot.create(:vm_vmware, :ext_management_system => src_ems_vmware, :ems_cluster => src_cluster_vmware) }
  let(:src_storage_1) { FactoryBot.create(:storage) }
  let(:src_storage_2) { FactoryBot.create(:storage) }
  let(:src_lan_1) { FactoryBot.create(:lan) }
  let(:src_lan_2) { FactoryBot.create(:lan) }
  let(:hardware) { FactoryBot.create(:hardware) }
  let(:nic_1) { FactoryBot.create(:guest_device_nic) }
  let(:nic_2) { FactoryBot.create(:guest_device_nic) }

  let(:svc_model_user) { MiqAeMethodService::MiqAeServiceUser.find(user.id) }
  let(:svc_model_group) { MiqAeMethodService::MiqAeServiceMiqGroup.find(group.id) }
  let(:svc_model_task) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask.find(task.id) }
  let(:svc_model_src_ems_vmware) { MiqAeMethodService::MiqAeServiceExtManagementSystem.find(src_ems_vmware) }
  let(:svc_model_src_cluster_vmware) { MiqAeMethodService::MiqAeServiceEmsCluster.find(src_cluster_vmware) }
  let(:svc_model_src_vm_vmware) { MiqAeMethodService::MiqAeServiceManageIQ_Providers_Vmware_InfraManager_Vm.find(src_vm_vmware.id) }
  let(:svc_model_src_storage_1) { MiqAeMethodService::MiqAeServiceStorage.find(src_storage_1) }
  let(:svc_model_src_storage_2) { MiqAeMethodService::MiqAeServiceStorage.find(src_storage_2) }
  let(:svc_model_src_lan_1) { MiqAeMethodService::MiqAeServiceLan.find(src_lan_1) }
  let(:svc_model_src_lan_2) { MiqAeMethodService::MiqAeServiceLan.find(src_lan_2) }
  let(:svc_model_hardware) { MiqAeMethodService::MiqAeServiceHardware.find(hardware) }
  let(:svc_model_guest_device_1) { MiqAeMethodService::MiqAeServiceGuestDevice.find(guest_device_1) }
  let(:svc_model_guest_device_2) { MiqAeMethodService::MiqAeServiceGuestDevice.find(guest_device_2) }
  let(:svc_model_nic_1) { MiqAeMethodService::MiqAeServiceGuestDevice.find(nic_1) }
  let(:svc_model_nic_2) { MiqAeMethodService::MiqAeServiceGuestDevice.find(nic_2) }

  let(:disk_1) { instance_double("disk", :device_name => "Hard disk 1", :device_type => "disk", :filename => "[datastore12] test_vm/test_vm.vmdk", :size => 17_179_869_184) }
  let(:disk_2) { instance_double("disk", :device_name => "Hard disk 2", :device_type => "disk", :filename => "[datastore12] test_vm/test_vm-2.vmdk", :size => 17_179_869_184) }

  let(:virtv2v_networks) do
    [
      { :source => svc_model_src_lan_1.name, :destination => svc_model_dst_lan_1.name, :mac_address => svc_model_nic_1.address },
      { :source => svc_model_src_lan_2.name, :destination => svc_model_dst_lan_2.name, :mac_address => svc_model_nic_2.address },
    ]
  end

  let(:virtv2v_disks) do
    [
      { :path => disk_1.filename, :size => disk_1.size, :percent => 0, :weight  => 50.0 },
      { :path => disk_2.filename, :size => disk_2.size, :percent => 0, :weight  => 50.0 }
    ]
  end

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
    allow(ManageIQ::Automate::Transformation::Common::Utils).to receive(:source_vm).and_return(svc_model_src_vm)

    allow(svc_model_src_vm).to receive(:hardware).and_return(svc_model_hardware)
    allow(disk_1).to receive(:storage).and_return(svc_model_src_storage_1)
    allow(disk_2).to receive(:storage).and_return(svc_model_src_storage_2)
    allow(svc_model_nic_1).to receive(:lan).and_return(svc_model_src_lan_1)
    allow(svc_model_nic_2).to receive(:lan).and_return(svc_model_src_lan_2)
  end

  before(:each) do
    ManageIQ::Automate::Transformation::Common::AssessTransformation.instance_variable_set(:@source_cluster, nil)
    ManageIQ::Automate::Transformation::Common::AssessTransformation.instance_variable_set(:@source_ems, nil)
    ManageIQ::Automate::Transformation::Common::AssessTransformation.instance_variable_set(:@destination_cluster, nil)
    ManageIQ::Automate::Transformation::Common::AssessTransformation.instance_variable_set(:@destination_ems, nil)
  end

  context "populate factory config" do
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }

    it "without vmtransformation_check_interval" do
      described_class.new(ae_service).populate_factory_config
      expect(ae_service.get_state_var(:factory_config)['vmtransformation_check_interval']).to eq('15.seconds')
    end

    it "with vmtransformation_check_interval" do
      ae_service.object['vmtransformation_check_interval'] = '30.seconds'
      described_class.new(ae_service).populate_factory_config
      expect(ae_service.get_state_var(:factory_config)['vmtransformation_check_interval']).to eq('30.seconds')
    end

    it "without vmpoweroff_check_interval" do
      described_class.new(ae_service).populate_factory_config
      expect(ae_service.get_state_var(:factory_config)['vmpoweroff_check_interval']).to eq('30.seconds')
    end

    it "with vmpoweroff_check_interval" do
      ae_service.object['vmpoweroff_check_interval'] = '1.minutes'
      described_class.new(ae_service).populate_factory_config
      expect(ae_service.get_state_var(:factory_config)['vmpoweroff_check_interval']).to eq('1.minutes')
    end
  end

  shared_examples_for "#populate_task_options" do
    it "task options" do
      allow(svc_model_src_vm).to receive(:power_state).and_return("on")
      described_class.new(ae_service).populate_task_options
      expect(svc_model_task.get_option(:source_vm_power_state)).to eq("on")
      expect(svc_model_task.get_option(:collapse_snapshots)).to be true
      expect(svc_model_task.get_option(:power_off)).to be true
    end
  end

  shared_examples_for "main" do
    it "global summary test" do
      allow(svc_model_src_vm).to receive(:power_state).and_return("on")
      allow(svc_model_task).to receive(:preflight_check).and_return(true)
      described_class.new(ae_service).main
      expect(svc_model_task.get_option(:source_vm_power_state)).to eq("on")
      expect(svc_model_task.get_option(:collapse_snapshots)).to be true
      expect(svc_model_task.get_option(:power_off)).to be true
      expect(ae_service.get_state_var(:factory_config)['vmtransformation_check_interval']).to eq('15.seconds')
      expect(ae_service.get_state_var(:factory_config)['vmpoweroff_check_interval']).to eq('30.seconds')
    end
  end

  context "source is vmware and destination is redhat" do
    let(:src_vm) { src_vm_vmware }
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    let(:svc_model_src_ems) { svc_model_src_ems_vmware }

    let(:dst_ems) { FactoryBot.create(:ems_redhat) }
    let(:svc_model_dst_ems) { MiqAeMethodService::MiqAeServiceExtManagementSystem.find(dst_ems.id) }
    let(:dst_cluster) { FactoryBot.create(:ems_cluster, :ext_management_system => dst_ems) }
    let(:svc_model_dst_cluster) { MiqAeMethodService::MiqAeServiceEmsCluster.find(dst_cluster.id) }
    let(:dst_storage) { FactoryBot.create(:storage) }
    let(:svc_model_dst_storage) { MiqAeMethodService::MiqAeServiceStorage.find(dst_storage.id) }
    let(:dst_lan_1) { FactoryBot.create(:lan) }
    let(:svc_model_dst_lan_1) { MiqAeMethodService::MiqAeServiceLan.find(dst_lan_1.id) }
    let(:dst_lan_2) { FactoryBot.create(:lan) }
    let(:svc_model_dst_lan_2) { MiqAeMethodService::MiqAeServiceLan.find(dst_lan_2.id) }

    let(:mapping) do
      FactoryBot.create(
        :transformation_mapping,
        :transformation_mapping_items => [
          FactoryBot.create(:transformation_mapping_item, :source => src_cluster_vmware, :destination => dst_cluster),
          FactoryBot.create(:transformation_mapping_item, :source => src_storage_1, :destination => dst_storage),
          FactoryBot.create(:transformation_mapping_item, :source => src_storage_2, :destination => dst_storage),
          FactoryBot.create(:transformation_mapping_item, :source => src_lan_1, :destination => dst_lan_1),
          FactoryBot.create(:transformation_mapping_item, :source => src_lan_2, :destination => dst_lan_2)
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

    it_behaves_like "#populate_task_options"
    it_behaves_like "main"
  end

  context "source is vmware and destination is openstack" do
    let(:src_vm) { src_vm_vmware }
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    let(:svc_model_src_ems) { svc_model_src_ems_vmware }

    let(:dst_ems) { FactoryBot.create(:ems_openstack_infra) }
    let(:svc_model_dst_ems) { MiqAeMethodService::MiqAeServiceExtManagementSystem.find(dst_ems.id) }
    let(:dst_cloud_tenant) { FactoryBot.create(:cloud_tenant, :ext_management_system => dst_ems) }
    let(:svc_model_dst_cloud_tenant) { MiqAeMethodService::MiqAeServiceCloudTenant.find(dst_cluster.id) }
    let(:dst_cloud_volume_type) { FactoryBot.create(:cloud_volume_type) }
    let(:svc_model_dst_cloud_volume_type) { MiqAeMethodService::MiqAeServiceCloudVolumeType.find(dst_cloud_volume_type.id) }
    let(:dst_cloud_network_1) { FactoryBot.create(:cloud_network) }
    let(:svc_model_cloud_network_1) { MiqAeMethodService::MiqAeServiceCloudNetwork.find(dst_cloud_network_1.id) }
    let(:dst_cloud_network_2) { FactoryBot.create(:cloud_network) }
    let(:svc_model_cloud_network_1) { MiqAeMethodService::MiqAeServiceCloudNetwork.find(dst_cloud_network_2.id) }

    let(:mapping) do
      FactoryBot.create(
        :transformation_mapping,
        :transformation_mapping_items => [
          FactoryBot.create(:transformation_mapping_item, :source => src_cluster_vmware, :destination => dst_cloud_tenant),
          FactoryBot.create(:transformation_mapping_item, :source => src_storage_1, :destination => dst_cloud_volume_type),
          FactoryBot.create(:transformation_mapping_item, :source => src_storage_2, :destination => dst_cloud_volume_type),
          FactoryBot.create(:transformation_mapping_item, :source => src_lan_1, :destination => dst_cloud_network_1),
          FactoryBot.create(:transformation_mapping_item, :source => src_lan_2, :destination => dst_cloud_network_2)
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

    it_behaves_like "#populate_task_options"
    it_behaves_like "main"
  end

  context "handle errors" do
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }

    it "sets cancel_requested option if preflight check returns false" do
      allow(svc_model_task).to receive(:preflight_check).and_return(false)
      errormsg = 'Preflight check has failed'
      expect { described_class.new(ae_service).main }.to raise_error(errormsg)
      expect(ae_service.get_state_var(:ae_state_progress)).to eq('message' => errormsg)
    end
  end
end
