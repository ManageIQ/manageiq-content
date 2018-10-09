require_domain_file
require File.join(ManageIQ::Content::Engine.root, 'content/automate/ManageIQ/Transformation/Common.class/__methods__/utils.rb')

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

  shared_examples_for "#populate_state_vars" do
    it "state_vars" do
      described_class.new(ae_service).populate_state_vars
      expect(ae_service.get_state_var(:source_ems_type)).to eq(svc_model_src_ems.ems_type)
      expect(ae_service.get_state_var(:destination_ems_type)).to eq(svc_model_dst_ems.ems_type)
    end
  end

  shared_examples_for "main" do
    it "global summary test" do
      allow(svc_model_src_vm).to receive(:power_state).and_return("on")
      described_class.new(ae_service).main
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

    it_behaves_like "#populate_task_options"
    it_behaves_like "#populate_state_vars"
    it_behaves_like "main"
  end

  context "catchall exception rescue" do
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }

    it "raises if task preflight check fails" do
      errormsg = 'Unexpected error'
      allow(task).to_receive(:preflight_check).and_raise(errormsg)
      expect { described_class.new(ae_service).main }.to raise_error(errormsg)
      expect(ae_service.get_state_var(:ae_state_progress)).to eq('message' => errormsg)
    end
  end
end
