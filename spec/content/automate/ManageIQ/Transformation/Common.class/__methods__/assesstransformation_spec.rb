require_domain_file

describe ManageIQ::Automate::Transformation::Common::AssessTransformation do
  let(:user) { FactoryGirl.create(:user_with_email_and_group) }
  let(:group) { FactoryGirl.create(:miq_group) }
  let(:task) { FactoryGirl.create(:service_template_transformation_plan_task) }
  let(:src_vm_vmware) { FactoryGirl.create(:vm_vmware) }
  let(:src_cluster) { FactoryGirl.create(:ems_cluster) }
  let(:src_ems_vmware) { FactoryGirl.create(:ems_vmware) }
  let(:dst_cluster) { FactoryGirl.create(:ems_cluster) }
  let(:dst_ems_redhat) { FactoryGirl.create(:ems_redhat) }
  let(:dst_ems_openstack) { FactoryGirl.create(:ems_openstack_infra) }
  let(:src_storage_1) { FactoryGirl.create(:storage) }
  let(:src_storage_2) { FactoryGirl.create(:storage) }
  let(:dst_storage) { FactoryGirl.create(:storage) }
  let(:src_lan_1) { FactoryGirl.create(:lan) }
  let(:src_lan_2) { FactoryGirl.create(:lan) }
  let(:dst_lan_1) { FactoryGirl.create(:lan) }
  let(:dst_lan_2) { FactoryGirl.create(:lan) }
  let(:hardware) { FactoryGirl.create(:hardware) }
  let(:nic_1) { FactoryGirl.create(:guest_device_nic) }
  let(:nic_2) { FactoryGirl.create(:guest_device_nic) }

  let(:svc_model_user) { MiqAeMethodService::MiqAeServiceUser.find(user.id) }
  let(:svc_model_group) { MiqAeMethodService::MiqAeServiceMiqGroup.find(group.id) }
  let(:svc_model_task) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask.find(task.id) }
  let(:svc_model_src_vm_vmware) { MiqAeMethodService::MiqAeServiceManageIQ_Providers_Vmware_InfraManager_Vm.find(src_vm_vmware.id) }
  let(:svc_model_src_cluster) { MiqAeMethodService::MiqAeServiceEmsCluster.find(src_cluster) }
  let(:svc_model_src_ems_vmware) { MiqAeMethodService::MiqAeServiceExtManagementSystem.find(src_ems_vmware) }
  let(:svc_model_dst_cluster) { MiqAeMethodService::MiqAeServiceEmsCluster.find(dst_cluster) }
  let(:svc_model_dst_ems_redhat) { MiqAeMethodService::MiqAeServiceExtManagementSystem.find(dst_ems_redhat) }
  let(:svc_model_dst_ems_openstack) { MiqAeMethodService::MiqAeServiceExtManagementSystem.find(dst_ems_openstack) }
  let(:svc_model_src_storage_1) { MiqAeMethodService::MiqAeServiceStorage.find(src_storage_1) }
  let(:svc_model_src_storage_2) { MiqAeMethodService::MiqAeServiceStorage.find(src_storage_2) }
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

  let(:disk_1) { instance_double("disk", :device_name => "Hard disk 1", :device_type => "disk", :filename => "[datastore12] test_vm/test_vm.vmdk", :size => 17179869184) }
  let(:disk_2) { instance_double("disk", :device_name => "Hard disk 2", :device_type => "disk", :filename => "[datastore12] test_vm/test_vm-2.vmdk", :size => 17179869184) }

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

  shared_examples_for "source and destination items" do
    it "source_cluster without cluster" do
      allow(svc_model_src_vm).to receive(:ems_cluster).and_return(nil)
      errormsg = "No source cluster"
      expect { described_class.new(ae_service).source_cluster }.to raise_error(errormsg)
    end

    it "source_cluster with cluster" do
      allow(svc_model_src_vm).to receive(:ems_cluster).and_return(svc_model_src_cluster)
      expect(described_class.new(ae_service).source_cluster.id).to eq(svc_model_src_cluster.id)
    end

    it "source_ems without ems" do
      allow(svc_model_src_vm).to receive(:ems_cluster).and_return(svc_model_src_cluster)
      allow(svc_model_src_cluster).to receive(:ext_management_system).and_return(nil)
      errormsg = "No source EMS"
      expect { described_class.new(ae_service).source_ems }.to raise_error(errormsg)
    end

    it "source_ems with ems" do
      allow(svc_model_src_vm).to receive(:ext_management_system).and_return(svc_model_src_ems)
      expect(described_class.new(ae_service).source_ems.id).to eq(svc_model_src_ems.id)
    end

    it "destination_cluster without cluster" do
      allow(svc_model_src_vm).to receive(:ems_cluster).and_return(svc_model_src_cluster)
      allow(svc_model_task).to receive(:transformation_destination).with(svc_model_src_cluster).and_return(nil)
      errormsg = "No destination cluster"
      expect { described_class.new(ae_service).destination_cluster }.to raise_error(errormsg)
    end

    it "destination_cluster with cluster" do
      allow(svc_model_src_vm).to receive(:ems_cluster).and_return(svc_model_src_cluster)
      allow(svc_model_task).to receive(:transformation_destination).with(svc_model_src_cluster).and_return(svc_model_dst_cluster)
      expect(described_class.new(ae_service).destination_cluster.id).to eq(svc_model_dst_cluster.id)
    end

    it "destination_ems without ems" do
      allow(svc_model_src_vm).to receive(:ems_cluster).and_return(svc_model_src_cluster)
      allow(svc_model_task).to receive(:transformation_destination).with(svc_model_src_cluster).and_return(svc_model_dst_cluster)
      allow(svc_model_dst_cluster).to receive(:ext_management_system).and_return(nil)
      errormsg = "No destination EMS"
      expect { described_class.new(ae_service).destination_ems }.to raise_error(errormsg)
    end

    it "destination_ems with ems" do
      allow(svc_model_src_vm).to receive(:ems_cluster).and_return(svc_model_src_cluster)
      allow(svc_model_task).to receive(:transformation_destination).with(svc_model_src_cluster).and_return(svc_model_dst_cluster)
      allow(svc_model_dst_cluster).to receive(:ext_management_system).and_return(svc_model_dst_ems)
      expect(described_class.new(ae_service).destination_ems.id).to eq(svc_model_dst_ems.id)
    end
  end

  context "source and destination items source vmware and destination redhat" do
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    let(:svc_model_src_ems) { svc_model_src_ems_vmware }
    let(:svc_model_dst_ems) { svc_model_dst_ems_redhat }

    it_behaves_like "source and destination items"
  end

  context "source and destination items source vmware and destination openstack" do
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    let(:svc_model_src_ems) { svc_model_src_ems_vmware }
    let(:svc_model_dst_ems) { svc_model_dst_ems_openstack }

    it_behaves_like "source and destination items"
  end

  context "transformation_type" do
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }

    it  "transformation_type with invalid source ems" do
      allow(svc_model_src_vm).to receive(:ext_management_system).and_return(svc_model_dst_ems_redhat)
      errormsg = "Unsupported source EMS type: #{svc_model_dst_ems_redhat.emstype}."
      expect { described_class.new(ae_service).transformation_type }.to raise_error(errormsg)
    end

    it "transformation_type with invalid destination ems" do
      allow(svc_model_src_vm).to receive(:ems_cluster).and_return(svc_model_src_cluster)
      allow(svc_model_src_vm).to receive(:ext_management_system).and_return(svc_model_src_ems_vmware)
      allow(svc_model_task).to receive(:transformation_destination).with(svc_model_src_cluster).and_return(svc_model_dst_cluster)
      allow(svc_model_dst_cluster).to receive(:ext_management_system).and_return(svc_model_src_ems_vmware)
      errormsg = "Unsupported destination EMS type: #{svc_model_src_ems_vmware.emstype}."
      expect { described_class.new(ae_service).transformation_type }.to raise_error(errormsg)
    end

    it "transformation_type with valid source and destination ems" do
      allow(svc_model_src_vm).to receive(:ems_cluster).and_return(svc_model_src_cluster)
      allow(svc_model_src_vm).to receive(:ext_management_system).and_return(svc_model_src_ems_vmware)
      allow(svc_model_task).to receive(:transformation_destination).with(svc_model_src_cluster).and_return(svc_model_dst_cluster)
      allow(svc_model_dst_cluster).to receive(:ext_management_system).and_return(svc_model_dst_ems_redhat)
      expect(described_class.new(ae_service).transformation_type).to eq("#{svc_model_src_ems_vmware.emstype}2#{svc_model_dst_ems_redhat.emstype}")
    end
  end

  shared_examples_for "virtv2v hardware" do
    it "source_vm has no disk" do
      allow(svc_model_src_vm.hardware).to receive(:disks).and_return([])
      expect(described_class.new(ae_service).virtv2v_disks).to eq([])
    end

    it "source_vm has disks, but src_storage_1 has no mapping" do
      allow(svc_model_hardware).to receive(:disks).and_return([disk_1, disk_2])
      allow(svc_model_task).to receive(:transformation_destination).with(svc_model_src_storage_1).and_return(nil)
      errormsg = "[#{svc_model_src_vm.name}] Disk #{disk_1.device_name} [#{svc_model_src_storage_1.name}] has no mapping. Aborting."
      expect { described_class.new(ae_service).virtv2v_disks }.to raise_error(errormsg)
    end

    it "source_vm has disks and storages have mapping" do
      allow(svc_model_hardware).to receive(:disks).and_return([disk_1, disk_2])
      allow(svc_model_task).to receive(:transformation_destination).with(svc_model_src_storage_1).and_return(svc_model_dst_storage)
      allow(svc_model_task).to receive(:transformation_destination).with(svc_model_src_storage_2).and_return(svc_model_dst_storage)
      allow(svc_model_src_vm).to receive(:allocated_disk_storage).and_return(disk_1.size + disk_2.size)
      expect(described_class.new(ae_service).virtv2v_disks).to eq(virtv2v_disks)
    end

     it "source_vm has no nic" do
      allow(svc_model_src_vm.hardware).to receive(:nics).and_return([])
      expect(described_class.new(ae_service).virtv2v_networks).to eq([])
    end

    it "source_vm has nics, but src_lan_1 has no mapping" do
      allow(svc_model_hardware).to receive(:nics).and_return([svc_model_nic_1, svc_model_nic_2])
      allow(svc_model_task).to receive(:transformation_destination).with(svc_model_src_lan_1).and_return(nil)
      errormsg = "[#{svc_model_src_vm.name}] NIC #{svc_model_nic_1.device_name} [#{svc_model_src_lan_1.name}] has no mapping. Aborting."
      expect { described_class.new(ae_service).virtv2v_networks }.to raise_error(errormsg)
    end

    it "source_vm has nicss and lans have mapping" do
      allow(svc_model_hardware).to receive(:nics).and_return([svc_model_nic_1, svc_model_nic_2])
      allow(svc_model_task).to receive(:transformation_destination).with(svc_model_src_lan_1).and_return(svc_model_dst_lan_1)
      allow(svc_model_task).to receive(:transformation_destination).with(svc_model_src_lan_2).and_return(svc_model_dst_lan_2)
      expect(described_class.new(ae_service).virtv2v_networks).to eq(virtv2v_networks)
    end
  end

  context "source vm is vmware" do
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }

    it_behaves_like "virtv2v hardware"
  end

  shared_examples_for "populate task options" do
    it "task options" do
      allow(svc_model_src_vm).to receive(:ems_cluster).and_return(svc_model_src_cluster)
      allow(svc_model_src_vm).to receive(:ext_management_system).and_return(svc_model_src_ems)
      allow(svc_model_task).to receive(:transformation_destination).with(svc_model_src_cluster).and_return(svc_model_dst_cluster)
      allow(svc_model_dst_cluster).to receive(:ext_management_system).and_return(svc_model_dst_ems)
      allow(svc_model_hardware).to receive(:disks).and_return([disk_1, disk_2])
      allow(svc_model_task).to receive(:transformation_destination).with(svc_model_src_storage_1).and_return(svc_model_dst_storage)
      allow(svc_model_task).to receive(:transformation_destination).with(svc_model_src_storage_2).and_return(svc_model_dst_storage)
      allow(svc_model_src_vm).to receive(:allocated_disk_storage).and_return(disk_1.size + disk_2.size)
      allow(svc_model_hardware).to receive(:nics).and_return([svc_model_nic_1, svc_model_nic_2])
      allow(svc_model_task).to receive(:transformation_destination).with(svc_model_src_lan_1).and_return(svc_model_dst_lan_1)
      allow(svc_model_task).to receive(:transformation_destination).with(svc_model_src_lan_2).and_return(svc_model_dst_lan_2)
      allow(svc_model_src_vm).to receive(:power_state).and_return("on")
      described_class.new(ae_service).populate_task_options
      expect(svc_model_task.get_option(:source_ems_id)).to eq(svc_model_src_ems.id)
      expect(svc_model_task.get_option(:destination_ems_id)).to eq(svc_model_dst_ems.id)
      expect(svc_model_task[:options][:virtv2v_networks]).to eq(virtv2v_networks)
      expect(svc_model_task[:options][:virtv2v_disks]).to eq(virtv2v_disks)
      expect(svc_model_task.get_option(:transformation_type)).to eq("#{svc_model_src_ems.emstype}2#{svc_model_dst_ems.emstype}")
      expect(svc_model_task.get_option(:source_vm_power_state)).to eq("on")
      expect(svc_model_task.get_option(:collapse_snapshots)).to be true
      expect(svc_model_task.get_option(:power_off)).to be true
    end
  end

  context "source is vmware and destination is redhat" do
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    let(:svc_model_src_ems) { svc_model_src_ems_vmware }
    let(:svc_model_dst_ems) { svc_model_dst_ems_redhat }

    it_behaves_like "populate task options"
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

  shared_examples_for "main" do
    it "global summary test" do
      allow(svc_model_src_vm).to receive(:ems_cluster).and_return(svc_model_src_cluster)
      allow(svc_model_src_vm).to receive(:ext_management_system).and_return(svc_model_src_ems)
      allow(svc_model_task).to receive(:transformation_destination).with(svc_model_src_cluster).and_return(svc_model_dst_cluster)
      allow(svc_model_dst_cluster).to receive(:ext_management_system).and_return(svc_model_dst_ems)
      allow(svc_model_hardware).to receive(:disks).and_return([disk_1, disk_2])
      allow(svc_model_task).to receive(:transformation_destination).with(svc_model_src_storage_1).and_return(svc_model_dst_storage)
      allow(svc_model_task).to receive(:transformation_destination).with(svc_model_src_storage_2).and_return(svc_model_dst_storage)
      allow(svc_model_src_vm).to receive(:allocated_disk_storage).and_return(disk_1.size + disk_2.size)
      allow(svc_model_hardware).to receive(:nics).and_return([svc_model_nic_1, svc_model_nic_2])
      allow(svc_model_task).to receive(:transformation_destination).with(svc_model_src_lan_1).and_return(svc_model_dst_lan_1)
      allow(svc_model_task).to receive(:transformation_destination).with(svc_model_src_lan_2).and_return(svc_model_dst_lan_2)
      allow(svc_model_src_vm).to receive(:power_state).and_return("on")
      described_class.new(ae_service).main
      expect(svc_model_task.get_option(:source_ems_id)).to eq(svc_model_src_ems.id)
      expect(svc_model_task.get_option(:destination_ems_id)).to eq(svc_model_dst_ems.id)
      expect(svc_model_task[:options][:virtv2v_networks]).to eq(virtv2v_networks)
      expect(svc_model_task[:options][:virtv2v_disks]).to eq(virtv2v_disks)
      expect(svc_model_task.get_option(:transformation_type)).to eq("#{svc_model_src_ems.emstype}2#{svc_model_dst_ems.emstype}")
      expect(svc_model_task.get_option(:source_vm_power_state)).to eq("on")
      expect(svc_model_task.get_option(:collapse_snapshots)).to be true
      expect(svc_model_task.get_option(:power_off)).to be true
      expect(ae_service.get_state_var(:factory_config)['vmtransformation_check_interval']).to eq('15.seconds')
      expect(ae_service.get_state_var(:factory_config)['vmpoweroff_check_interval']).to eq('30.seconds')
    end
   end

  context "source is vmware and destination is redhat" do
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    let(:svc_model_src_ems) { svc_model_src_ems_vmware }
    let(:svc_model_dst_ems) { svc_model_dst_ems_redhat }

    it_behaves_like "main"
  end

  context "catchall exception rescue" do
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }

    it "forcefully raise" do
      errormsg = 'No source EMS'
      expect { described_class.new(ae_service).main }.to raise_error(errormsg)
      expect(ae_service.get_state_var(:ae_state_progress)).to eq('message' => errormsg)
    end
  end
end
