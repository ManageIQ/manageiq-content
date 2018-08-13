require_domain_file

describe ManageIQ::Automate::Transformation::Infrastructure::VM::Common::CheckVmInInventory do
  let(:user) { FactoryGirl.create(:user_with_email_and_group) }
  let(:task) { FactoryGirl.create(:service_template_transformation_plan_task) }
  let(:src_vm_vmware) { FactoryGirl.create(:vm_vmware) }
  let(:dst_vm_redhat) { FactoryGirl.create(:vm_redhat) }
  let(:dst_vm_openstack) { FactoryGirl.create(:vm_openstack) }
  let(:src_cluster) { FactoryGirl.create(:ems_cluster) }
  let(:dst_cluster) { FactoryGirl.create(:ems_cluster) }
  let(:dst_ems) { FactoryGirl.create(:ext_management_system) }

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
    )
  end

  let(:current_object) { Spec::Support::MiqAeMockObject.new }
  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root).tap do |service|
      current_object.parent = root
      service.current_object = current_object
    end
  end

  context "validate task" do
    it "when task is nil" do
      errormsg = 'ERROR - A service_template_transformation_plan_task is needed for this method to continue'
      expect { described_class.new(ae_service).task }.to raise_error(errormsg)
    end

    it "when task is present" do
      ae_service.root['service_template_transformation_plan_task'] = svc_model_task
      expect(described_class.new(ae_service).task.id).to eq(svc_model_task.id)
    end
  end

  shared_examples_for "validate source and destination vms" do
    let(:svc_vmdb_handle) { MiqAeMethodService::MiqAeServiceVm }

    before do
      ae_service.root['service_template_transformation_plan_task'] = svc_model_task
    end

    it "when task.source vm is nil" do
      errormsg = 'ERROR - Source VM has not been defined in the task'
      expect { described_class.new(ae_service).source_vm }.to raise_error(errormsg)
    end

    it "when task.source is present" do
      ae_service.root['service_template_transformation_plan_task'] = svc_model_task
      allow(svc_model_task).to receive(:source) { svc_model_src_vm }
      expect(described_class.new(ae_service).source_vm.id).to eq(svc_model_src_vm.id)
    end

    it "when destination_vm is nil" do
      ae_service.root['service_template_transformation_plan_task'] = svc_model_task
      allow(svc_model_task).to receive(:source) { svc_model_src_vm }
      allow(svc_model_task).to receive(:transformation_destination).and_return(svc_model_dst_cluster)
      allow(svc_model_dst_cluster).to receive(:ext_management_system).and_return(svc_model_dst_ems)
      allow(ae_service).to receive(:vmdb).with(:vm).and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:find_by).with(:name => svc_model_src_vm.name, :ems_id => svc_model_dst_ems.id).and_return(nil)
      expect(described_class.new(ae_service).destination_vm).to be_nil
      described_class.new(ae_service).main
      expect(ae_service.root['ae_result']).to eq('retry')
      expect(ae_service.root['ae_retry_interval']).to eq('15.seconds')
    end

    it "when destination_vm is present" do
      ae_service.root['service_template_transformation_plan_task'] = svc_model_task
      allow(svc_model_task).to receive(:source) { svc_model_src_vm }
      allow(svc_model_task).to receive(:transformation_destination).and_return(svc_model_dst_cluster)
      allow(svc_model_dst_cluster).to receive(:ext_management_system).and_return(svc_model_dst_ems)
      allow(ae_service).to receive(:vmdb).with(:vm).and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:find_by).with(:name => svc_model_src_vm.name, :ems_id => svc_model_dst_ems.id).and_return(svc_model_dst_vm)
      expect(described_class.new(ae_service).destination_vm.id).to eq(svc_model_dst_vm.id)
      described_class.new(ae_service).main
      expect(svc_model_task.get_option(:destination_vm_id)).to eq(svc_model_dst_vm.id)
    end
  end

  context "validate when source is vmware and destination redhat" do
    let(:src_vm) { src_vm_vmware }
    let(:dst_vm) { dst_vm_redhat }
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    let(:svc_model_dst_vm) { svc_model_dst_vm_redhat }

    it_behaves_like "validate source and destination vms"
  end

  context "validate when source is vmware and destination openstack" do
    let(:src_vm) { src_vm_vmware }
    let(:dst_vm) { dst_vm_openstack }
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    let(:svc_model_dst_vm) { svc_model_dst_vm_openstack }

    it_behaves_like "validate source and destination vms"
  end

  context "catchall exception rescue" do
    before do
      allow(svc_model_task).to receive(:source).and_raise(StandardError.new('kaboom'))
    end

    it "forcefully raise" do
      errormsg = 'ERROR - A service_template_transformation_plan_task is needed for this method to continue'
      expect { described_class.new(ae_service).main }.to raise_error(errormsg)
      expect(ae_service.get_state_var(:ae_state_progress)).to eq('message' => errormsg)
    end
  end
end
