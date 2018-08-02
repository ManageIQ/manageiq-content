require domain_file

describe ManageIQ::Automate::Transformation::Common::Utils do
  let(:user) { FactoryGirl.create(:user_with_email_and_group) }
  let(:task) { FactoryGirl.create(:service_template_transformation_plan_task) }
  let(:src_vm_vmware) { FactoryGirl.create(:vm_vmware) }
  let(:dst_vm_redhat) { FactoryGirl.create(:vm_redhat) }
  let(:dst_vm_openstack) { FactoryGirl.create(:vm_openstack) }

  let(:svc_model_user) { MiqAeMethodService::MiqAeServiceUser.find(user.id) }
  let(:svc_model_task) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask.find(task.id) }
  let(:svc_model_src_vm_vmware) { MiqAeMethodService::MiqAeServiceManageIQ_Providers_Vmware_InfraManager_Vm.find(src_vm_vmware.id) }
  let(:svc_model_dst_vm_redhat) { MiqAeMethodService::MiqAeServiceManageIQ_Providers_Redhat_InfraManager_Vm.find(dst_vm_redhat.id) }
  let(:svc_model_dst_vm_openstack) { MiqAeMethodService::MiqAeServiceManageIQ_Providers_Openstack_CloudManager_Vm.find(dst_vm_openstack.id) }

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

  context "transformation phase" do
    it "with task" do
      ae_service.root['state_machine_phase'] = 'transformation'
      expect(described_class.transformation_phase(ae_service)).to eq('transformation')
    end

    it "with task_id" do
      ae_service.root['state_machine_phase'] = 'cleanup'
      expect(described_class.transformation_phase(ae_service)).to eq('cleanup')
    end

    it "failure" do
      ae_service.root['state_machine_phase'] = 'invalid'
      errormsg = 'ERROR - Migration phase is not valid'
      expect { described_class.transformation_phase(ae_service) }.to raise_error(errormsg)
    end
  end

  shared_examples_for "transformation_task" do
    it "with task" do
      ae_service.root['service_template_transformation_plan_task'] = svc_model_task
      expect(described_class.transformation_task(ae_service).id).to eq(svc_model_task.id)
      expect(described_class.task(ae_service).id).to eq(svc_model_task.id)
    end

    it "without task" do
      errormsg = 'ERROR - A service_template_transformation_plan_task is needed for this method to continue'
      expect(described_class.transformation_task(ae_service)).to raise_error(errormsg)
      expect(described_class.task(ae_service)).to raise_error(errormsg)
    end
  end

  context "transformation_task vmware to redhat" do
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    let(:svc_model_dst_vm) { svc_model_dst_vm_redhat }

    it_behaves_like "transformation_task"
  end

  context "transformation_task vmware to openstack" do
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    let(:svc_model_dst_vm) { svc_model_dst_vm_openstack }

    it_behaves_like "transformation_task"
  end

  shared_examples_for "cleanup_task" do
    let(:svc_vmdb_handle) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask }

    it "with task_id and with task" do
      ae_service.root['service_template_transformation_plan_task_id'] = svc_model_task.id
      allow(ae_service).to receive(:vmdb).with(:service_template_transformation_plan_task).and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:find_by).with(:id => svc_model_task.id).and_return(svc_model_task)
      expect(described_class.cleanup_task(ae_service).id).to eq(svc_model_task.id)
      expect(described_class.task(ae_service).id).to eq(svc_model_task.id)
    end

    it "with task_id and without task" do
      ae_service.root['service_template_transformation_plan_task_id'] = svc_model_task.id
      allow(ae_service).to receive(:vmdb).with(:service_template_transformation_plan_task).and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:find_by).with(:id => svc_model_task.id).and_return(nil)
      errormsg = 'ERROR - A service_template_transformation_plan_task is needed for this method to continue'
      expect(described_class.cleanup_task(ae_service)).to raise_error(errormsg)
      expect(described_class.task(ae_service)).to raise_error(errormsg)
    end

    it "without task_id" do
      errormsg = 'ERROR - A service_template_transformation_plan_task is needed for this method to continue'
      expect(described_class.cleanup_task(ae_service)).to raise_error(errormsg)
      expect(described_class.task(ae_service)).to raise_error(errormsg)
    end
  end

  context "cleanup_task vmware to redhat" do
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    let(:svc_model_dst_vm) { svc_model_dst_vm_redhat }

    it_behaves_like "cleanup_task"
  end

  context "cleanup_task vmware to openstack" do
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    let(:svc_model_dst_vm) { svc_model_dst_vm_openstack }

    it_behaves_like "cleanup_task"
  end

  shared_examples_for "task" do
    it "in transformation" do
      ae_service.root['state_machine_phase'] = 'transformation'
      ae_service.root['service_template_transformation_plan_task'] = svc_model_task
      expect(described_class.transformation_task(ae_service).id).to eq(svc_model_task.id)
      expect(described_class.task(ae_service).id).to eq(svc_model_task.id)
    end

    it "in cleanup" do
      ae_service.root['state_machine_phase'] = 'cleanup'
      ae_service.root['service_template_transformation_plan_task_id'] = svc_model_task.id
      allow(ae_service).to receive(:vmdb).with(:service_template_transformation_plan_task).and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:find_by).with(:id => svc_model_task.id).and_return(svc_model_task)
      expect(described_class.cleanup_task(ae_service).id).to eq(svc_model_task.id)
      expect(described_class.task(ae_service).id).to eq(svc_model_task.id)
    end
  end

  shared_examples_for "source_vm" do
    before do
      ae_service.root['state_machine_phase'] = 'transformation'
      ae_service.root['service_template_transformation_plan_task'] = svc_model_task
    end

    it "with source vm" do
      allow(svc_model_task).to receive(:source) { svc_model_src_vm }
      expect(described_class.source_vm(ae_service).id).to eq(svc_model_src_vm.id)
    end

    it "without source vm" do
      allow(svc_model_task).to receive(:source).and_return(nil)
      errormsg = 'ERROR - Source VM has not been defined in the task'
      expect(described_class.source_vm(ae_service)).to raise_error(errormsg)
    end
  end

  context "source_vm vmware" do
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    it_behaves_like "source_vm"
  end

  shared_examples_for "destination_vm" do
    let(:svc_vmdb_handle) { MiqAeMethodService::MiqAeServiceVm }

    before do
      ae_service.root['state_machine_phase'] = 'transformation'
      ae_service.root['service_template_transformation_plan_task'] = svc_model_task
    end

    it "with destination vm" do
      allow(svc_model_task).to receive(:get_option).with(:destination_vm_id).and_return(nil)
      expect(described_class.destination_vm(ae_service)).to be_nil
    end

    it "without destination vm" do
      allow(svc_model_task).to receive(:get_option).with(:destination_vm_id).and_return(svc_model_dst_vm.id)
      allow(ae_service).to receive(:vmdb).with(:vm).and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:find_by).with(:id => svc_model_dst_vm.id).and_return(svc_model_dst_vm)
      expect(described_class.destination_vm(ae_service).id).to eq(svc_model_dst_vm.id)
    end
  end

  context "destination_vm redhat" do
    let(:svc_model_dst_vm) { svc_model_dst_vm_redhat }
    it_behaves_like "destination_vm"
  end

  context "destination_vm openstack" do
    let(:svc_model_dst_vm) { svc_model_dst_vm_openstack }
    it_behaves_like "destination_vm"
  end

  shared_examples_for "task_and_vms" do
    let(:svc_vmdb_handle) { MiqAeMethodService::MiqAeServiceVm }

    before do
      ae_service.root['state_machine_phase'] = 'transformation'
      ae_service.root['service_template_transformation_plan_task'] = svc_model_task
      allow(svc_model_task).to receive(:source) { svc_model_src_vm }
      allow(svc_model_task).to receive(:get_option).with(:destination_vm_id).and_return(svc_model_dst_vm.id)
      allow(ae_service).to receive(:vmdb).with(:vm).and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:find_by).with(:id => svc_model_dst_vm.id).and_return(svc_model_dst_vm)
    end

    it "task_and_vms in transformation with destination_vm" do
      ae_service.root['service_template_transformation_plan_task'] = svc_model_task
      described_class.task_and_vms(ae_service)
      expect(@task.id).to eq(svc_model_task.id)
      expect(@source_vm.id).to eq(svc_model_src_vm.id)
      expect(@destination_vm.id).to eq(svc_model_dst_vm.id)
    end
  end

  context "task_and_vms vmware to redhat" do
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    let(:svc_model_dst_vm) { svc_model_dst_vm_redhat }

    it_behaves_like "task_and_vms"
  end

  context "task_and_vms vmware to openstack" do
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    let(:svc_model_dst_vm) { svc_model_dst_vm_openstack }

    it_behaves_like "task_and_vms"
  end
end
