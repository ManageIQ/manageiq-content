require_domain_file

describe ManageIQ::Automate::Transformation::Common::Utils do
  let(:user) { FactoryBot.create(:user_with_email_and_group) }
  let(:task) { FactoryBot.create(:service_template_transformation_plan_task) }
  let(:src_vm_vmware) { FactoryBot.create(:vm_vmware) }
  let(:dst_vm_redhat) { FactoryBot.create(:vm_redhat) }
  let(:dst_vm_openstack) { FactoryBot.create(:vm_openstack) }

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

  before(:each) do
    ManageIQ::Automate::Transformation::Common::Utils.instance_variable_set(:@transformation_phase, nil)
    ManageIQ::Automate::Transformation::Common::Utils.instance_variable_set(:@task, nil)
    ManageIQ::Automate::Transformation::Common::Utils.instance_variable_set(:@source_vm, nil)
    ManageIQ::Automate::Transformation::Common::Utils.instance_variable_set(:@destination_vm, nil)
  end

  context "transformation phase" do
    it "is transformation" do
      ae_service.root['state_machine_phase'] = 'transformation'
      expect(described_class.transformation_phase(ae_service)).to eq('transformation')
    end

    it "is cleanup" do
      ae_service.root['state_machine_phase'] = 'cleanup'
      expect(described_class.transformation_phase(ae_service)).to eq('cleanup')
    end

    it "is invalid" do
      ae_service.root['state_machine_phase'] = 'invalid'
      errormsg = 'ERROR - Transformation phase is not valid'
      expect { described_class.transformation_phase(ae_service) }.to raise_error(errormsg)
    end
  end

  shared_examples_for "transformation_task" do
    before do
      ae_service.root['state_machine_phase'] = 'transformation'
    end

    it "without task" do
      errormsg = 'ERROR - A service_template_transformation_plan_task is needed for this method to continue'
      expect { described_class.transformation_task(ae_service) }.to raise_error(errormsg)
    end

    it "with task" do
      ae_service.root['service_template_transformation_plan_task'] = svc_model_task
      expect(described_class.transformation_task(ae_service).id).to eq(svc_model_task.id)
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

    before do
      ae_service.root['state_machine_phase'] = 'cleanup'
    end

    it "with task_id and with task" do
      ae_service.root['service_template_transformation_plan_task_id'] = svc_model_task.id
      allow(ae_service).to receive(:vmdb).with(:service_template_transformation_plan_task).and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:find_by).with(:id => svc_model_task.id).and_return(svc_model_task)
      expect(described_class.cleanup_task(ae_service).id).to eq(svc_model_task.id)
    end

    it "with task_id and without task" do
      ae_service.root['service_template_transformation_plan_task_id'] = svc_model_task.id
      allow(ae_service).to receive(:vmdb).with(:service_template_transformation_plan_task).and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:find_by).with(:id => svc_model_task.id).and_return(nil)
      errormsg = 'ERROR - A service_template_transformation_plan_task is needed for this method to continue'
      expect { described_class.cleanup_task(ae_service) }.to raise_error(errormsg)
    end

    it "without task_id" do
      errormsg = 'ERROR - service_template_transformation_plan_task_id is not defined'
      expect { described_class.cleanup_task(ae_service) }.to raise_error(errormsg)
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
      expect(described_class.task(ae_service).id).to eq(svc_model_task.id)
    end

    it "in cleanup" do
      ae_service.root['state_machine_phase'] = 'cleanup'
      ae_service.root['service_template_transformation_plan_task_id'] = svc_model_task.id
      allow(ae_service).to receive(:vmdb).with(:service_template_transformation_plan_task).and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:find_by).with(:id => svc_model_task.id).and_return(svc_model_task)
      expect(described_class.task(ae_service).id).to eq(svc_model_task.id)
    end
  end

  shared_examples_for "source_vm" do
    before do
      ae_service.root['state_machine_phase'] = 'transformation'
      ae_service.root['service_template_transformation_plan_task'] = svc_model_task
    end

    it "with source vm" do
      allow(svc_model_task).to receive(:source).and_return(svc_model_src_vm)
      expect(described_class.source_vm(ae_service).id).to eq(svc_model_src_vm.id)
    end

    it "without source vm" do
      allow(svc_model_task).to receive(:source).and_return(nil)
      errormsg = 'ERROR - Source VM has not been defined in the task'
      expect { described_class.source_vm(ae_service) }.to raise_error(errormsg)
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

    it "without destination_vm_id" do
      allow(svc_model_task).to receive(:get_option).with(:destination_vm_id).and_return(nil)
      expect(described_class.destination_vm(ae_service)).to be_nil
    end

    it "with destination_vm_id and without destination vm" do
      allow(svc_model_task).to receive(:get_option).with(:destination_vm_id).and_return(svc_model_dst_vm.id)
      allow(ae_service).to receive(:vmdb).with(:vm).and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:find_by).with(:id => svc_model_dst_vm.id).and_return(nil)
      errormsg = "ERROR - No match for destination_vm_id in VMDB"
      expect { described_class.destination_vm(ae_service) }.to raise_error(errormsg)
    end

    it "with destination_vm_id and with destination vm" do
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
end
