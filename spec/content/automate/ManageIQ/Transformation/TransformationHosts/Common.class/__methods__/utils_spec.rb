require_domain_file
#require File.join(ManageIQ::Content::Engine.root, 'content/automate/ManageIQ/Transformation/TransformationHosts/Common.class/__methods__/utils.rb')

describe ManageIQ::Automate::Transformation::TransformationHosts::Common::Utils do
  let(:user) { FactoryGirl.create(:user_with_email_and_group) }
  let(:task_1) { FactoryGirl.create(:service_template_transformation_plan_task) }
  let(:task_2) { FactoryGirl.create(:service_template_transformation_plan_task) }
  let(:task_3) { FactoryGirl.create(:service_template_transformation_plan_task) }
  let(:dst_ems) { FactoryGirl.create(:ext_management_system) }
  let(:src_host) { FactoryGirl.create(:host) }
  let(:src_vm_vmware) { FactoryGirl.create(:vm_vmware) }
  let(:src_cluster) { FactoryGirl.create(:ems_cluster) }
  let(:dst_cluster) { FactoryGirl.create(:ems_cluster) }
  let(:src_storage) { FactoryGirl.create(:storage) }
  let(:dst_storage) { FactoryGirl.create(:storage) }
  let(:src_lan_1) { FactoryGirl.create(:lan) }
  let(:src_lan_2) { FactoryGirl.create(:lan) }
  let(:dst_lan_1) { FactoryGirl.create(:lan) }
  let(:dst_lan_2) { FactoryGirl.create(:lan) }
  let(:hardware) { FactoryGirl.create(:hardware) }
  let(:nic_1) { FactoryGirl.create(:guest_device_nic) }
  let(:nic_2) { FactoryGirl.create(:guest_device_nic) }
  let(:conversion_host_1) { FactoryGirl.create(:conversion_host) }
  let(:conversion_host_2) { FactoryGirl.create(:conversion_host) }
  let(:conversion_host_3) { FactoryGirl.create(:conversion_host) }

  let(:svc_model_user) { MiqAeMethodService::MiqAeServiceUser.find(user.id) }
  let(:svc_model_task_1) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask.find(task_1.id) }
  let(:svc_model_task_2) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask.find(task_2.id) }
  let(:svc_model_task_3) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask.find(task_3.id) }
  let(:svc_model_dst_ems) { MiqAeMethodService::MiqAeServiceExtManagementSystem.find(dst_ems.id) }
  let(:svc_model_src_host) { MiqAeMethodService::MiqAeServiceHost.find(src_host.id) }
  let(:svc_model_src_vm_vmware) { MiqAeMethodService::MiqAeServiceManageIQ_Providers_Vmware_InfraManager_Vm.find(src_vm_vmware.id) }
  let(:svc_model_src_cluster) { MiqAeMethodService::MiqAeServiceEmsCluster.find(src_cluster.id) }
  let(:svc_model_dst_cluster) { MiqAeMethodService::MiqAeServiceEmsCluster.find(dst_cluster.id) }
  let(:svc_model_src_storage) { MiqAeMethodService::MiqAeServiceStorage.find(src_storage) }
  let(:svc_model_dst_storage) { MiqAeMethodService::MiqAeServiceStorage.find(dst_storage) }
  let(:svc_model_src_lan_1) { MiqAeMethodService::MiqAeServiceLan.find(src_lan_1) }
  let(:svc_model_src_lan_2) { MiqAeMethodService::MiqAeServiceLan.find(src_lan_2) }
  let(:svc_model_dst_lan_1) { MiqAeMethodService::MiqAeServiceLan.find(dst_lan_1) }
  let(:svc_model_dst_lan_2) { MiqAeMethodService::MiqAeServiceLan.find(dst_lan_2) }
  let(:svc_model_hardware) { MiqAeMethodService::MiqAeServiceHardware.find(hardware) }
  let(:svc_model_guest_device_1) { MiqAeMethodService::MiqAeServiceGuestDevice.find(guest_device_1) }
  let(:svc_model_guest_device_2) { MiqAeMethodService::MiqAeServiceGuestDevice.find(guest_device_2) }
  let(:svc_model_nic_1) { MiqAeMethodService::MiqAeServiceGuestDevice.find(nic_1) }
  let(:svc_model_nic_2) { MiqAeMethodService::MiqAeServiceGuestDevice.find(nic_2) }
  let(:svc_model_conversion_host_1) { MiqAeMethodService::MiqAeServiceConversionHost.find(conversion_host_1.id) }
  let(:svc_model_conversion_host_2) { MiqAeMethodService::MiqAeServiceConversionHost.find(conversion_host_2.id) }
  let(:svc_model_conversion_host_3) { MiqAeMethodService::MiqAeServiceConversionHost.find(conversion_host_3.id) }

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

  let(:svc_vmdb_handle) { MiqAeMethodService::MiqAeServiceConversionHost }

  before do
    allow(ae_service).to receive(:vmdb).with(:conversion_host).and_return(svc_vmdb_handle)
    allow(svc_vmdb_handle).to receive(:all).and_return([svc_model_conversion_host_1, svc_model_conversion_host_2, svc_model_conversion_host_3])
    allow(svc_model_conversion_host_1).to receive(:ext_management_system).and_return(svc_model_dst_ems)
    allow(svc_model_conversion_host_2).to receive(:ext_management_system).and_return(svc_model_dst_ems)
    allow(svc_model_conversion_host_3).to receive(:ext_management_system).and_return(nil)
    allow(svc_model_conversion_host_1).to receive(:eligible?).and_return(true)
    allow(svc_model_conversion_host_2).to receive(:eligible?).and_return(true)
    allow(svc_model_conversion_host_3).to receive(:eligible?).and_return(false)
    allow(svc_model_conversion_host_1).to receive(:active_tasks).and_return([svc_model_task_1, svc_model_task_2])
    allow(svc_model_conversion_host_2).to receive(:active_tasks).and_return([svc_model_task_3])
    allow(svc_model_task_1).to receive(:destination_ems).and_return(svc_model_dst_ems)
    allow(svc_model_task_2).to receive(:destination_ems).and_return(svc_model_dst_ems)
    allow(svc_model_task_3).to receive(:destination_ems).and_return(svc_model_dst_ems)
  end

  describe "#transformation_hosts" do
    it { expect(described_class.transformation_hosts(svc_model_dst_ems, ae_service)).to eq([svc_model_conversion_host_1, svc_model_conversion_host_2]) }
  end

  describe "#eligible_transformation_hosts" do
    it { expect(described_class.eligible_transformation_hosts(svc_model_dst_ems, ae_service)).to eq([svc_model_conversion_host_2, svc_model_conversion_host_1]) }
  end

  describe "#get_runners_count_by_ems" do
    it { expect(described_class.get_runners_count_by_ems(svc_model_dst_ems, ae_service)).to eq(3) }
  end

  describe "#ems_max_runners" do
    it "with custom attribute" do
      allow(svc_model_dst_ems).to receive(:custom_get).with('Max Transformation Runners').and_return('2')
      expect(described_class.ems_max_runners(svc_model_dst_ems, {})).to eq(2)
    end

    it "with factory_config key" do
      expect(described_class.ems_max_runners(svc_model_dst_ems, {'ems_max_runners' => 2}, ae_service)).to eq(2)
    end

    it "with overridden max_runners" do
      expect(described_class.ems_max_runners(svc_model_dst_ems, {}, 2)).to eq(2)
    end

    it "with default" do
      expect(described_class.ems_max_runners(svc_model_dst_ems, {})).to eq(10)
    end
  end

  describe "#get_transformation_host" do
    before do
      allow(svc_model_task_1).to receive(:conversion_host).and_return(svc_model_conversion_host_1)
      allow(svc_model_task_2).to receive(:conversion_host).and_return(svc_model_conversion_host_2)
      allow(svc_model_task_3).to receive(:conversion_host).and_return(nil)
    end

    it "when ems max runners is reached" do
      expect(described_class.get_transformation_host(svc_model_task_3, { 'ems_max_runners' => 2 }, ae_service)).to be_nil
    end

    it "without an eligible host" do
      allow(svc_model_conversion_host_1).to receive(:eligible?).and_return(false)
      allow(svc_model_conversion_host_2).to receive(:eligible?).and_return(false)
      expect(described_class.get_transformation_host(svc_model_task_3, {}, ae_service)).to be_nil
    end

    it "with an eligible host" do
      expect(described_class.get_transformation_host(svc_model_task_3, {}, ae_service)).to eq(svc_model_conversion_host_2)
    end
  end
end
