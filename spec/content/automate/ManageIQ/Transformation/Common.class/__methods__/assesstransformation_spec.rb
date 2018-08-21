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

  let(:svc_model_user) { MiqAeMethodService::MiqAeServiceUser.find(user.id) }
  let(:svc_model_group) { MiqAeMethodService::MiqAeServiceMiqGroup.find(group.id) }
  let(:svc_model_task) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask.find(task.id) }
  let(:svc_model_src_vm_vmware) { MiqAeMethodService::MiqAeServiceManageIQ_Providers_Vmware_InfraManager_Vm.find(src_vm_vmware.id) }
  let(:svc_model_src_cluster) { MiqAeMethodService::MiqAeServiceEmsCluster.find(src_cluster) }
  let(:svc_model_src_ems_vmware) { MiqAeMethodService::MiqAeServiceExtManagementSystem.find(src_ems_vmware) }
  let(:svc_model_dst_cluster) { MiqAeMethodService::MiqAeServiceEmsCluster.find(dst_cluster) }
  let(:svc_model_dst_ems_redhat) { MiqAeMethodService::MiqAeServiceExtManagementSystem.find(dst_ems_redhat) }
  let(:svc_model_dst_ems_openstack) { MiqAeMethodService::MiqAeServiceExtManagementSystem.find(dst_ems_openstack) }

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
    ManageIQ::Automate::Transformation::Common::AssessTransformation.instance_variable_set(:@task, svc_model_task)
    ManageIQ::Automate::Transformation::Common::AssessTransformation.instance_variable_set(:@source_vm, svc_model_src_vm)
    ManageIQ::Automate::Transformation::Common::AssessTransformation.instance_variable_set(:@source_cluster, nil)
    ManageIQ::Automate::Transformation::Common::AssessTransformation.instance_variable_set(:@source_ems, nil)
    ManageIQ::Automate::Transformation::Common::AssessTransformation.instance_variable_set(:@destination_cluster, nil)
    ManageIQ::Automate::Transformation::Common::AssessTransformation.instance_variable_set(:@destination_ems, nil)
  end

  def set_vm_identity
    svc_model_src_vm.add_to_service(svc_model_service)
    src_vm.tag_with("prod", :ns => "/managed", :cat => "environment")
    svc_model_src_vm.custom_set('attr', 'value')
    svc_model_src_vm.owner = svc_model_user
    svc_model_src_vm.group = svc_model_group
    svc_model_src_vm.retires_on = retirement_date
    svc_model_src_vm.retirement_warn = 7
  end

  shared_examples_for "validate task_and_vms" do
    it "when task is absent" do
      errormsg = 'ERROR - A service_template_transformation_plan_task is needed for this method to continue'
      expect { described_class.new(ae_service).task_and_vms }.to raise_error(errormsg)
    end

    it "when source vm is absent" do
      allow(ManageIQ::Automate::Transformation::Common::Utils).to receive(:task).and_return(svc_model_task)
      errormsg = 'ERROR - Source VM has not been defined in the task'
      expect { described_class.new(ae_service).new.task_and_vms }.to raise_error(errormsg)
    end

    it "when task is present" do
      allow(ManageIQ::Automate::Transformation::Common::Utils).to receive(:task).and_return(svc_model_task)
      allow(ManageIQ::Automate::Transformation::Common::Utils).to receive(:source_vm).and_return(svc_model_src_vm)
      described_class.new(ae_service).new.task_and_vms
      expect(ManageIQ::Automate::Transformation::Common::AssessTransformation.instance_variable_get(:@task).id).to eq(svc_model_task.id)
      expect(ManageIQ::Automate::Transformation::Common::AssessTransformation.instance_variable_get(:@source_vm).id).to eq(svc_model_src_vm.id)
    end
  end

  context "validate task_and_vms when source is vmware" do
    let(:src_vm) { src_vm_vmware }
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }

    it_behaves_like "validate task_and_vms"
  end

  shared_examples_for "source and destination items" do
    it "source_cluster without cluster" do
      allow(svc_model_src_vm).to receive(:ems_cluster).and_return(nil)
      errormsg = "No source cluster for VM '#{svc_model_src_vm.name}'"
      expect { described_class.new.source_cluster }.to raise_error(errormsg)
    end

    it "source_cluster with cluster" do
      allow(svc_model_src_vm).to receive(:ems_cluster).and_return(svc_model_src_cluster)
      described_class.new.source_cluster
      expect(ManageIQ::Automate::Transformation::Common::AssessTransformation.instance_variable_get(:@source_cluster).id).to eq(svc_model_src_cluster.id)
    end

    it "source_ems without ems" do
      allow(svc_model_src_vm).to receive(:ext_management_system).and_return(nil)
      errormsg = "No source EMS for VM '#{svc_model_src_vm.name}'"
      expect { described_class.new.source_ems }.to raise_error(errormsg)
    end

    it "source_cluster with cluster" do
      allow(svc_model_src_vm).to receive(:ext_management_system).and_return(svc_model_src_ems)
      described_class.new.source_ems
      expect(ManageIQ::Automate::Transformation::Common::AssessTransformation.instance_variable_get(:@source_ems).id).to eq(svc_model_src_ems.id)
    end

    it "destination_cluster without cluster" do
      allow(svc_model_src_vm).to receive(:ems_cluster).and_return(svc_model_src_cluster)
      allow(svc_model_task).to receive(:transformation_destination).with(svc_model_src_cluster).and_return(nil)
      errormsg = "No destination cluster for VM '#{svc_model_src_vm.name}'"
      expect { described_class.new.destination_cluster }.to raise_error(errormsg)
    end

    it "destination_cluster with cluster" do
      allow(svc_model_src_vm).to receive(:ems_cluster).and_return(svc_model_src_cluster)
      allow(svc_model_task).to receive(:transformation_destination).with(svc_model_src_cluster).and_return(svc_model_dst_cluster)
      described_class.new.destination_cluster
      expect(ManageIQ::Automate::Transformation::Common::AssessTransformation.instance_variable_get(:@destination_cluster).id).to eq(svc_model_dst_cluster.id)
    end

    it "destination_ems without ems" do
      allow(svc_model_src_vm).to receive(:ems_cluster).and_return(svc_model_src_cluster)
      allow(svc_model_task).to receive(:transformation_destination).with(svc_model_src_cluster).and_return(svc_model_dst_cluster)
      allow(svc_model_dst_cluster).to receive(:ext_management_system).and_return(nil)
      errormsg = "No destination EMS for VM '#{svc_model_src_vm.name}'"
      expect { described_class.new.destination_ems }.to raise_error(errormsg)
    end

    it "source_cluster with cluster" do
      allow(svc_model_src_vm).to receive(:ems_cluster).and_return(svc_model_src_cluster)
      allow(svc_model_task).to receive(:transformation_destination).with(svc_model_src_cluster).and_return(svc_model_dst_cluster)
      allow(svc_model_src_vm).to receive(:ext_management_system).and_return(svc_model_dst_ems)
      described_class.new.destination_ems
      expect(ManageIQ::Automate::Transformation::Common::AssessTransformation.instance_variable_get(:@destination_ems).id).to eq(svc_model_dst_ems.id)
    end

  end

  context "source and destination items source vmware and destination redhat" do
    let(:src_vm) { src_vm_vmware }
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    let(:src_ems) { src_ems_vmware }
    let(:svc_model_src_ems) { svc_model_src_ems_vmware }
    let(:dst_ems) { dst_ems_redhat }
    let(:svc_model_dst_ems) { svc_model_dst_ems_redhat }

    it_behaves_like "source and destination items"
  end

 context "source and destination items source vmware and destination openstack" do
    let(:src_vm) { src_vm_vmware }
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    let(:src_ems) { src_ems_vmware }
    let(:svc_model_src_ems) { svc_model_src_ems_vmware }
    let(:dst_ems) { dst_ems_openstack }
    let(:svc_model_dst_ems) { svc_model_dst_ems_openstack }

    it_behaves_like "source and destination items"
  end

  context "source and destination items with invalid source vmware and destination redhat" do
    let(:src_vm) { src_vm_vmware }
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    let(:src_ems) { src_ems_vmware }
    let(:svc_model_src_ems) { svc_model_src_ems_vmware }
    let(:dst_ems) { FactoryGirl.create(:ems_vmware) }
    let(:svc_model_dst_ems) { MiqAeMethodService::MiqAeServiceExtManagementSystem.find(dst_ems) }

    it_behaves_like "source and destination items"
  end

   context "source and destination items source vmware and invalid destination" do
    let(:src_vm) { src_vm_vmware }
    let(:svc_model_src_vm) { svc_model_src_vm_vmware }
    let(:src_ems) { src_ems_vmware }
    let(:svc_model_src_ems) { svc_model_src_ems_vmware }
    let(:dst_ems) { FactoryGirl.create(:ems_vmware) }
    let(:svc_model_dst_ems) { MiqAeMethodService::MiqAeServiceExtManagementSystem.find(dst_ems) }

    it_behaves_like "source and destination items"
  end

  context "transformation_type with invalid source ems" do
    ManageIQ::Automate::Transformation::Common::AssessTransformation.instance_variable_set(:@source_ems, svc_model_dst_ems_redhat)
    errormsg = "Unsupported source EMS type: #{svc_model_dst_ems_redhat.emstype}."
    expect { described_class.new.transformation_type }.to raise_error(errormsg)
  end

  context "transformation_type with invalid destination ems" do
    ManageIQ::Automate::Transformation::Common::AssessTransformation.instance_variable_set(:@source_ems, svc_model_src_ems_vmware)
    ManageIQ::Automate::Transformation::Common::AssessTransformation.instance_variable_set(:@destination_ems, svc_model_src_ems_vmware)
    errormsg = "Unsupported destination EMS type: #{svc_model_src_ems_vmware.emstype}."
    expect { described_class.new.transformation_type }.to raise_error(errormsg)
  end

  context "transformation_type with valid source and destination ems" do
    ManageIQ::Automate::Transformation::Common::AssessTransformation.instance_variable_set(:@source_ems, svc_model_src_ems_vmware)
    ManageIQ::Automate::Transformation::Common::AssessTransformation.instance_variable_set(:@destination_ems, svc_model_dst_ems_redhat)
    expect(described_class.new(ae_service).transformation_type).to eq("#{svc_model_src_ems_vmware.emstype}2#{svc_model_dst_ems_redhat.emstype}")
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
