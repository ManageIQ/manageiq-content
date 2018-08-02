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

  context "migration phase" do
    it "with task" do
      ae_service.root['service_template_transformation_plan_task'] = svc_model_task
      expect(described_class.migration_phase(ae_service)).to eq('migration')
    end

    it "with task_id" do
      ae_service.root['service_template_transformation_plan_task_id'] = svc_model_task.id
      expect(described_class.migration_phase(ae_service)).to eq('cleanup')
    end

    it "failure" do
      expect { described_class.migration_phase(ae_service) }.to raise_error(StandardError, 'Migration phase is not valid')
    end
  end

  shared_examples_for "task_in_migration" do
    it "with task" do
      ae_service.root['service_template_transformation_plan_task'] = svc_model_task
      expect(described_class.task_in_migration(ae_service).id).to eq(svc_model_task.id)
    end

    it "without task" do
      expect(described_class.task_in_migration(ae_service)).to be_nil
    end
  end

  context "task_in_migration vmware to redhat" do
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    let(:svc_model_dst_vm) { svc_model_dst_vm_redhat }

    it_behaves_like "task_in_migration"
  end

  context "task_in_migration vmware to openstack" do
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    let(:svc_model_dst_vm) { svc_model_dst_vm_openstack }

    it_behaves_like "task_in_migration"
  end

  shared_examples_for "task_in_cleanup" do
    it "with task_id" do
      ae_service.root['service_template_transformation_plan_task_id'] = svc_model_task.id
      expect(described_class.task_in_cleanup(ae_service).id).to eq(svc_model_task.id)
    end

    it "without task_id" do
      expect(described_class.task_in_cleanup(ae_service)).to be_nil
    end
  end

  context "task_in_cleanup vmware to redhat" do
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    let(:svc_model_dst_vm) { svc_model_dst_vm_redhat }

    it_behaves_like "task_in_cleanup"
  end

  context "task_in_cleanup vmware to openstack" do
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    let(:svc_model_dst_vm) { svc_model_dst_vm_openstack }

    it_behaves_like "task_in_cleanup"
  end

  shared_examples_for "vm_at_source" do
    before do
      allow(svc_model_task).to receive(:source) { svc_model_src_vm }
    end

    it "vm" do
      expect(described_class.vm_at_source(svc_model_task, ae_service).id).to eq(svc_model_src_vm.id)
    end
  end

  context "vm_at_source vmware" do
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    it_behaves_like "vm_at_source"
  end

  shared_examples_for "vm_at_destination" do
    before do
      allow(svc_model_task).to receive(:get_option).with(:destination_vm_id).and_return(svc_model_dst_vm.id)
    end

    it "vm" do
      expect(described_class.vm_at_destination(svc_model_task, ae_service).id).to eq(svc_model_dst_vm.id)
    end
  end

  context "vm_at_source vmware to redhat" do
    let(:svc_model_dst_vm) { svc_model_dst_vm_redhat }
    it_behaves_like "vm_at_destination"
  end

  context "vm_at_source vmware to openstack" do
    let(:svc_model_dst_vm) { svc_model_dst_vm_openstack }
    it_behaves_like "vm_at_destination"
  end

  shared_examples_for "task_and_vm" do
    before do
      allow(svc_model_task).to receive(:source) { svc_model_src_vm }
      allow(svc_model_task).to receive(:get_option).with(:destination_vm_id).and_return(svc_model_dst_vm.id)
    end

    it "task_and_vm in migration at source" do
      ae_service.root['service_template_transformation_plan_task'] = svc_model_task
      r_task, r_vm = described_class.task_and_vm('source', ae_service)
      expect(r_task.id).to eq(svc_model_task.id)
      expect(r_vm.id).to eq(svc_model_src_vm.id)
    end

    it "task_and_vm in migration at destination" do
      ae_service.root['service_template_transformation_plan_task'] = svc_model_task
      r_task, r_vm = described_class.task_and_vm('destination', ae_service)
      expect(r_task.id).to eq(svc_model_task.id)
      expect(r_vm.id).to eq(svc_model_dst_vm.id)
    end

    it "task_and_vm_in cleanup at source" do
      ae_service.root['service_template_transformation_plan_task'] = svc_model_task
      r_task, r_vm = described_class.task_and_vm('source', ae_service)
      expect(r_task.id).to eq(svc_model_task.id)
      expect(r_vm.id).to eq(svc_model_src_vm.id)
    end

    it "task_and_vm_in cleanup at destination" do
      ae_service.root['service_template_transformation_plan_task'] = svc_model_task
      r_task, r_vm = described_class.task_and_vm('destination', ae_service)
      expect(r_task.id).to eq(svc_model_task.id)
      expect(r_vm.id).to eq(svc_model_dst_vm.id)
    end
  end

  context "task_and_vm migration vmware to redhat" do
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    let(:svc_model_dst_vm) { svc_model_dst_vm_redhat }

    it_behaves_like "task_and_vm"
  end

  context "task_and_vm migration vmware to openstack" do
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    let(:svc_model_dst_vm) { svc_model_dst_vm_openstack }

    it_behaves_like "task_and_vm"
  end
end
