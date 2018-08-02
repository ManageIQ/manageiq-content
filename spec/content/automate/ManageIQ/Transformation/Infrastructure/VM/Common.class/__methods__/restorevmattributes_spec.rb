require domain_file

describe ManageIQ::Automate::Transformation::Infrastructure::VM::Common::RestoreVmAttributes do
  let(:user) { FactoryGirl.create(:user_with_email_and_group) }
  let(:task) { FactoryGirl.create(:service_template_transformation_plan_task) }
  let(:src_vm_vmware) { FactoryGirl.create(:vm_vmware) }
  let(:dst_vm_redhat) { FactoryGirl.create(:vm_redhat) }
  let(:dst_vm_openstack) { FactoryGirl.create(:vm_openstack) }
  let(:service) { FactoryGirl.create(:service) }
  let!(:parent_classification) { FactoryGirl.create(:classification, :name => "environment", :description => "Environment") }
  let!(:classification) { FactoryGirl.create(:classification, :name => "prod", :description => "Production", :parent => parent_classification) }

  let(:svc_model_user) { MiqAeMethodService::MiqAeServiceUser.find(user.id) }
  let(:svc_model_task) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask.find(task.id) }
  let(:svc_model_src_vm_vmware) { MiqAeMethodService::MiqAeServiceManageIQ_Providers_Vmware_InfraManager_Vm.find(src_vm_vmware.id) }
  let(:svc_model_dst_vm_redhat) { MiqAeMethodService::MiqAeServiceManageIQ_Providers_Redhat_InfraManager_Vm.find(dst_vm_redhat.id) }
  let(:svc_model_dst_vm_openstack) { MiqAeMethodService::MiqAeServiceManageIQ_Providers_Openstack_CloudManager_Vm.find(dst_vm_openstack.id) }
  let(:svc_model_service) { MiqAeMethodService::MiqAeServiceService.find(service.id) }

  let(:root) do
    Spec::Support::MiqAeMockObject.new(
      'cureent' => current_object,
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

  def set_vm_identity
    svc_model_src_vm.add_to_service(svc_model_service)
    src_vm.tag_with("prod", :ns => "/managed", :cat => "environment")
    svc_model_src_vm.custom_set('attr', 'value')
  end

  context "validate task" do
    it "when task is nil" do
      errormsg = 'ERROR - task object is not passed in'
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

    it "when task.source is nil" do
      errormsg = 'ERROR - task.source is not set'
      expect { described_class.new(ae_service).source_vm }.to raise_error(errormsg)
    end

    it "when task.source is present" do
      ae_service.root['service_template_transformation_plan_task'] = svc_model_task
      allow(svc_model_task).to receive(:source) { svc_model_src_vm }
      expect(described_class.new(ae_service).source_vm.id).to eq(svc_model_src_vm.id)
    end

    it "when destination_vm_id option is absent" do
      ae_service.root['service_template_transformation_plan_task'] = svc_model_task
      errormsg = "ERROR - task has no ':destination_vm_id' option"
      expect { described_class.new(ae_service).destination_vm }.to raise_error(errormsg)
    end

    it "when destination_vm is nil" do
      allow(svc_model_task).to receive(:get_option).with(:destination_vm_id).and_return(svc_model_dst_vm.id)
      allow(ae_service).to receive(:vmdb).with(:vm).and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:find_by).with(:id => svc_model_dst_vm.id).and_return(nil)
      errormsg = 'ERROR - destination_vm is nil'
      expect { described_class.new(ae_service).destination_vm }.to raise_error(errormsg)
    end

    it "when destination_vm present" do
      allow(svc_model_task).to receive(:get_option).with(:destination_vm_id).and_return(svc_model_dst_vm.id)
      allow(ae_service).to receive(:vmdb).with(:vm).and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:find_by).with(:id => svc_model_dst_vm.id).and_return(svc_model_dst_vm)
      expect(described_class.new(ae_service).destination_vm.id).to eq(svc_model_dst_vm.id)
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

  shared_examples_for "restore identity" do
    let(:svc_vmdb_handle) { MiqAeMethodService::MiqAeServiceVm }

    before do
      ae_service.root['service_template_transformation_plan_task'] = svc_model_task
      allow(svc_model_task).to receive(:source) { svc_model_src_vm }
      allow(svc_model_task).to receive(:get_option).with(:destination_vm_id).and_return(svc_model_dst_vm.id)
      allow(ae_service).to receive(:vmdb).with(:vm).and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:find_by).with(:id => svc_model_dst_vm.id).and_return(svc_model_dst_vm)
      set_vm_identity
    end

    it "restore service" do
      described_class.new(ae_service).vm_restore_service(svc_model_src_vm, svc_model_dst_vm)
      expect(svc_model_src_vm.service).to be_nil
      expect(svc_model_dst_vm.service.id).to eq(svc_model_service.id)
    end

    it "restore tags" do
      described_class.new(ae_service).vm_restore_tags(svc_model_src_vm, svc_model_dst_vm)
      expect(svc_model_dst_vm.tags).to eq(["environment/prod"])
    end

    it "restore customer attributes" do
      described_class.new(ae_service).vm_restore_custom_attributes(svc_model_src_vm, svc_model_dst_vm)
      expect(svc_model_dst_vm.custom_get('attr')).to eq('value')
    end

    it "restore identity" do
      described_class.new(ae_service).main
      expect(svc_model_src_vm.service).to be_nil
      expect(svc_model_dst_vm.service.id).to eq(svc_model_service.id)
      expect(svc_model_dst_vm.tags).to eq(["environment/prod"])
      expect(svc_model_dst_vm.custom_get('attr')).to eq('value')
    end
  end

  context "restore when source is vmware and destination redhat" do
    let(:src_vm) { src_vm_vmware }
    let(:dst_vm) { dst_vm_redhat }
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    let(:svc_model_dst_vm) { svc_model_dst_vm_redhat }

    it_behaves_like "restore identity"
  end

  context "restore when source is vmware and destination openstack" do
    let(:src_vm) { src_vm_vmware }
    let(:dst_vm) { dst_vm_openstack }
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    let(:svc_model_dst_vm) { svc_model_dst_vm_openstack }

    it_behaves_like "restore identity"
  end

  context "catchall exception rescue" do
    before do
      allow(svc_model_task).to receive(:source).and_raise(StandardError.new('kaboom'))
    end

    it "forcefully raise" do
      errormsg = 'ERROR - task object is not passed in'
      expect { described_class.new(ae_service).main }.to raise_error(errormsg)
      expect(ae_service.get_state_var(:ae_state_progress)).to eq('message' => errormsg)
    end
  end
end
