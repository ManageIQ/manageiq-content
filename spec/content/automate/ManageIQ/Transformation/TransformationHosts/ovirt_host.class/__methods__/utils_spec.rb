require_domain_file
require File.join(ManageIQ::Content::Engine.root, 'content/automate/ManageIQ/Transformation/TransformationHosts/Common.class/__methods__/utils.rb')
require File.join(ManageIQ::Content::Engine.root, 'content/automate/ManageIQ/Transformation/Infrastructure/VM/vmwarews.class/__methods__/utils.rb')
require File.join(ManageIQ::Content::Engine.root, 'content/automate/ManageIQ/Transformation/TransformationHosts/ovirt_host.class/__methods__/utils.rb')

describe ManageIQ::Automate::Transformation::TransformationHosts::Common::Utils do
  let(:user) { FactoryGirl.create(:user_with_email_and_group) }
  let(:task_1) { FactoryGirl.create(:service_template_transformation_plan_task) }
  let(:task_2) { FactoryGirl.create(:service_template_transformation_plan_task) }
  let(:task_3) { FactoryGirl.create(:service_template_transformation_plan_task) }
  let(:dst_ems_redhat) { FactoryGirl.create(:ems_redhat) }
  let(:src_host) { FactoryGirl.create(:host) }
  let(:dst_host_1) { FactoryGirl.create(:host) }
  let(:dst_host_2) { FactoryGirl.create(:host) }
  let(:dst_host_3) { FactoryGirl.create(:host) }
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

  let(:svc_model_user) { MiqAeMethodService::MiqAeServiceUser.find(user.id) }
  let(:svc_model_task_1) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask.find(task_1.id) }
  let(:svc_model_task_2) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask.find(task_2.id) }
  let(:svc_model_task_3) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask.find(task_3.id) }
  let(:svc_model_dst_ems_redhat) { MiqAeMethodService::MiqAeServiceExtManagementSystem.find(dst_ems_redhat.id) }
  let(:svc_model_src_host) { MiqAeMethodService::MiqAeServiceHost.find(src_host.id) }
  let(:svc_model_dst_host_1) { MiqAeMethodService::MiqAeServiceHost.find(dst_host_1.id) }
  let(:svc_model_dst_host_2) { MiqAeMethodService::MiqAeServiceHost.find(dst_host_2.id) }
  let(:svc_model_dst_host_3) { MiqAeMethodService::MiqAeServiceHost.find(dst_host_3.id) }
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

  before do
    allow(svc_model_dst_ems_redhat).to receive(:hosts).and_return([svc_model_dst_host_1, svc_model_dst_host_2, svc_model_dst_host_3])
    allow(svc_model_dst_host_1).to receive(:tagged_with?).with('v2v_transformation_host', 'true').and_return(true)
    allow(svc_model_dst_host_2).to receive(:tagged_with?).with('v2v_transformation_host', 'true').and_return(true)
    allow(svc_model_dst_host_1).to receive(:tags).with('v2v_transformation_method').and_return('vddk')
    allow(svc_model_dst_host_2).to receive(:tags).with('v2v_transformation_method').and_return('vddk')
  end

  before(:each) do
#    ManageIQ::Automate::Transformation::TransformationThrottler::Utils.instance_variable_set(:@task, nil)
  end

  context "#get_runners_count_by_host" do
    let(:svc_vmdb_handle) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask }

    it "without only one task" do
      allow(ae_service).to receive(:vmdb).with(:service_template_transformation_plan_task).and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:where).with(:state => 'active').and_return([svc_model_task_1, svc_model_task_2])
      allow(svc_model_task_1).to receive(:get_option).with(:transformation_host_id).and_return(svc_model_dst_host_1.id)
      expect(described_class.get_runners_count_by_host(svc_model_dst_host_1, ae_service)).to eq(1)
    end
  end

  context "#host_max_runners" do
    it "with custom attribute" do
      allow(svc_model_dst_host_1).to receive(:custom_get).with('Max Transformation Runners').and_return('2')
      expect(described_class.host_max_runners(svc_model_dst_host_1, {})).to eq(2)
    end

    it "with factory_config key" do
      expect(described_class.host_max_runners(svc_model_dst_host_1, {'transformation_host_max_runners' => 2}, handle = ae_service)).to eq(2)
    end

    it "with overridden max_runners" do
      expect(described_class.host_max_runners(svc_model_dst_host_1, {}, 2)).to eq(2)
    end

    it "with default" do
      expect(described_class.host_max_runners(svc_model_dst_host_1, {})).to eq(10)
    end
  end

  context "#transformation_hosts" do
    let(:svc_vmdb_handle) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask }

    it "filter out untagged hosts and order tagged hosts" do
      allow(ae_service).to receive(:vmdb).with(:service_template_transformation_plan_task).and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:where).with(:state => 'active').and_return([svc_model_task_1, svc_model_task_2, svc_model_task_3])
      allow(svc_model_task_1).to receive(:get_option).with(:transformation_host_id).and_return(svc_model_dst_host_1.id)
      allow(svc_model_task_2).to receive(:get_option).with(:transformation_host_id).and_return(svc_model_dst_host_1.id)
      allow(svc_model_task_3).to receive(:get_option).with(:transformation_host_id).and_return(svc_model_dst_host_2.id)

      expect(described_class.transformation_hosts(svc_model_dst_ems_redhat, {}, ae_service)).to eq([
       {
         :type                  => 'OVirtHost',
         :transformation_method => 'vddk',
         :host                  => svc_model_dst_host_2,
         :runners               => {
           :current => 1,
           :maximum => 10
         }
       },
       {
         :type                  => 'OVirtHost',
         :transformation_method => 'vddk',
         :host                  => svc_model_dst_host_1,
         :runners               => {
           :current => 2,
           :maximum => 10
         }
       }
      ])
    end
  end

  context "#eligible_transformation_hosts" do
    let(:svc_vmdb_handle) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask }

    it "filter out hosts that reached their max runners" do
      allow(ae_service).to receive(:vmdb).with(:service_template_transformation_plan_task).and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:where).with(:state => 'active').and_return([svc_model_task_1, svc_model_task_2, svc_model_task_3])
      allow(svc_model_task_1).to receive(:get_option).with(:transformation_host_id).and_return(svc_model_dst_host_1.id)
      allow(svc_model_task_2).to receive(:get_option).with(:transformation_host_id).and_return(svc_model_dst_host_1.id)
      allow(svc_model_task_3).to receive(:get_option).with(:transformation_host_id).and_return(svc_model_dst_host_2.id)
      allow(svc_model_dst_host_1).to receive(:custom_get).with('Max Transformation Runners').and_return('2')

      expect(described_class.eligible_transformation_hosts(svc_model_dst_ems_redhat, {}, ae_service)).to eq([
       {
         :type                  => 'OVirtHost',
         :transformation_method => 'vddk',
         :host                  => svc_model_dst_host_2,
         :runners               => {
           :current => 1,
           :maximum => 10
         }
       }
      ])
    end
  end

  context "#get_runners_count_by_ems" do
    let(:svc_vmdb_handle) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask }

    it "mixed hosts configurations" do
      allow(ae_service).to receive(:vmdb).with(:service_template_transformation_plan_task).and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:where).with(:state => 'active').and_return([svc_model_task_1, svc_model_task_2, svc_model_task_3])
      allow(svc_model_task_1).to receive(:get_option).with(:transformation_host_id).and_return(svc_model_dst_host_1.id)
      allow(svc_model_task_2).to receive(:get_option).with(:transformation_host_id).and_return(svc_model_dst_host_1.id)
      allow(svc_model_task_3).to receive(:get_option).with(:transformation_host_id).and_return(svc_model_dst_host_2.id)
      expect(described_class.get_runners_count_by_ems(svc_model_dst_ems_redhat, {}, ae_service)).to eq(3)
    end
  end

  context "#ems_max_runners" do
    it "with custom attribute" do
      allow(svc_model_dst_ems_redhat).to receive(:custom_get).with('Max Transformation Runners').and_return('2')
      expect(described_class.ems_max_runners(svc_model_dst_ems_redhat, {})).to eq(2)
    end

    it "with factory_config key" do
      expect(described_class.ems_max_runners(svc_model_dst_ems_redhat, {'ems_max_runners' => 2}, handle = ae_service)).to eq(2)
    end

    it "with overridden max_runners" do
      expect(described_class.ems_max_runners(svc_model_dst_ems_redhat, {}, 2)).to eq(2)
    end

    it "with default" do
      expect(described_class.ems_max_runners(svc_model_dst_ems_redhat, {})).to eq(10)
    end
  end

  context "#get_transformation_host" do
    let(:svc_vmdb_handle_ems) { MiqAeMethodService::MiqAeServiceExtManagementSystem }
    let(:svc_vmdb_handle_transformation_task) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask }

    before do
      allow(ae_service).to receive(:vmdb).with(:ext_management_system).and_return(svc_vmdb_handle_ems)
      allow(svc_vmdb_handle_ems).to receive(:find_by).with(:id => svc_model_dst_ems_redhat.id).and_return(svc_model_dst_ems_redhat)
      allow(ae_service).to receive(:vmdb).with(:service_template_transformation_plan_task).and_return(svc_vmdb_handle_transformation_task)
      allow(svc_vmdb_handle_transformation_task).to receive(:where).with(:state => 'active').and_return([svc_model_task_1, svc_model_task_2, svc_model_task_3])
      allow(svc_model_task_3).to receive(:get_option).with(:destination_ems_id).and_return(svc_model_dst_ems_redhat.id)
      allow(svc_model_task_1).to receive(:get_option).with(:transformation_host_id).and_return(svc_model_dst_host_1.id)
      allow(svc_model_task_2).to receive(:get_option).with(:transformation_host_id).and_return(svc_model_dst_host_2.id)
      allow(svc_model_task_3).to receive(:get_option).with(:transformation_host_id).and_return(nil)
    end

    it "when ems max runners is reached" do
      expect(described_class.get_transformation_host(svc_model_task_3, { 'ems_max_runners' => 2 }, ae_service)).to be_nil
    end

    it "without an eligible host" do
      expect(described_class.get_transformation_host(svc_model_task_3, { 'transformation_host_max_runners' => 1 }, ae_service)).to be_nil
    end

    it "with an eligible host" do
      allow(svc_model_dst_host_1).to receive(:custom_get).with('Max Transformation Runners').and_return('1')
      expect(described_class.get_transformation_host(svc_model_task_3, {}, ae_service)).to eq(['OVirtHost', svc_model_dst_host_2, 'vddk'])
    end
  end

  context "#virtv2vwrapper_options as when transformation type is vmwarews2rhevm" do
    before do
      allow(svc_model_task_1).to receive(:get_option).with(:transformation_type).and_return('vmwarews2rhevm')
      svc_model_task_1[:options][:virtv2v_disks] = virtv2v_disks
      svc_model_task_1[:options][:virtv2v_networks] = virtv2v_networks
      allow(svc_model_task_1).to receive(:source).and_return(svc_model_src_vm_vmware)
      allow(svc_model_src_vm_vmware).to receive(:ems_cluster).and_return(svc_model_src_cluster)
      allow(svc_model_task_1).to receive(:transformation_destination).with(svc_model_src_cluster).and_return(svc_model_dst_cluster)
      allow(svc_model_dst_cluster).to receive(:ext_management_system).and_return(svc_model_dst_ems_redhat)
      allow(svc_model_dst_ems_redhat).to receive(:authentication_password).and_return('rhv_passwd')
      allow(svc_model_src_vm_vmware).to receive(:hardware).and_return(svc_model_hardware)
      allow(svc_model_hardware).to receive(:disks).and_return([disk_1, disk_2])
      allow(disk_1).to receive(:storage).and_return(svc_model_src_storage)
      allow(svc_model_task_1).to receive(:transformation_destination).with(svc_model_src_storage).and_return(svc_model_dst_storage)
      allow(svc_model_hardware).to receive(:nics).and_return([svc_model_nic_1, svc_model_nic_2])
      allow(svc_model_task_1).to receive(:transformation_destination).with(svc_model_src_lan_1).and_return(svc_model_dst_lan_1)
      allow(svc_model_task_1).to receive(:transformation_destination).with(svc_model_src_lan_2).and_return(svc_model_dst_lan_2)
      allow(svc_model_src_vm_vmware).to receive(:host).and_return(svc_model_src_host)
      allow(svc_model_src_host).to receive(:ipaddress).and_return('10.0.0.1')
      allow(svc_model_src_host).to receive(:authentication_userid).and_return('esx_user')
      allow(svc_model_src_host).to receive(:authentication_password).and_return('esx_passwd')
      allow(ManageIQ::Automate::Transformation::Infrastructure::VM::VMware::Utils).to receive(:host_fingerprint).with(svc_model_src_host).and_return('01:23:45:67:89:ab:cd:ef:01:23:45:67:89:ab:cd:ef:01:23:45:67')
    end

    it "when transformation method is vddk" do
      allow(svc_model_task_1).to receive(:get_option).with(:transformation_method).and_return('vddk')
      expect(described_class.virtv2vwrapper_options(svc_model_task_1)).to eq({
        :vm_name             => svc_model_src_vm_vmware.name,
        :transport_method    => 'vddk',
        :vmware_fingerprint  => '01:23:45:67:89:ab:cd:ef:01:23:45:67:89:ab:cd:ef:01:23:45:67',
        :vmware_uri          => "esx://esx_user@10.0.0.1/?no_verify=1",
        :vmware_password     => 'esx_passwd',
        :rhv_url             => "https://#{svc_model_dst_ems_redhat.hostname}/ovirt-engine/api",
        :rhv_cluster         => svc_model_dst_cluster.name,
        :rhv_storage         => svc_model_dst_storage.name,
        :rhv_password        => 'rhv_passwd',
        :source_disks        => [ disk_1.filename, disk_2.filename ],
        :network_mappings    => virtv2v_networks,
        :install_drivers     => true,
        :insecure_connection => true
      })
    end

    it "when transformation method is ssh" do
      allow(svc_model_task_1).to receive(:get_option).with(:transformation_method).and_return('ssh')
      expect(described_class.virtv2vwrapper_options(svc_model_task_1)).to eq({
        :vm_name             => "ssh://root@10.0.0.1/vmfs/volumes/#{svc_model_src_storage.name}/#{svc_model_src_vm_vmware.location}",
        :transport_method    => 'ssh',
        :rhv_url             => "https://#{svc_model_dst_ems_redhat.hostname}/ovirt-engine/api",
        :rhv_cluster         => svc_model_dst_cluster.name,
        :rhv_storage         => svc_model_dst_storage.name,
        :rhv_password        => 'rhv_passwd',
        :source_disks        => [ disk_1.filename, disk_2.filename ],
        :network_mappings    => virtv2v_networks,
        :install_drivers     => true,
        :insecure_connection => true
      })
    end
  end

  context "#remote_command" do
    it "check constantize with ovirt host" do
      allow(svc_model_task_1).to receive(:get_option).with(:transformation_host_type).and_return('OVirtHost')
      allow(ManageIQ::Automate::Transformation::TransformationHosts::OVirtHost::Utils).to receive(:remote_command).with(svc_model_dst_host_1, 'my_command', 'test stdin').and_return({ :success => true, :stdout => 'test stdout', :rc => 0 })
      expect(ManageIQ::Automate::Transformation::TransformationHosts::OVirtHost::Utils).to receive(:remote_command).with(svc_model_dst_host_1, 'my_command', 'test stdin', nil)
      described_class.remote_command(svc_model_task_1, svc_model_dst_host_1, 'my_command', 'test stdin')
    end
  end
end
