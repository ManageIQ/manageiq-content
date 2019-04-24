require_domain_file

describe ManageIQ::Automate::AutomationManagement::AnsibleTower::Operations::StateMachines::Job::LaunchAnsibleJob do
  let(:job_class) { MiqAeMethodService::MiqAeServiceManageIQ_Providers_AnsibleTower_AutomationManager_Job }
  let(:jt_class) { MiqAeMethodService::MiqAeServiceManageIQ_Providers_AnsibleTower_AutomationManager_ConfigurationScript }
  let(:user) { FactoryGirl.create(:user_with_group) }
  let(:vm) { FactoryGirl.create(:vm) }
  let(:manager) { FactoryGirl.create(:automation_manager_ansible_tower, :name => "AT1") }
  let(:svc_vm) { MiqAeMethodService::MiqAeServiceVm.find(vm.id) }
  let(:job_template) do
    FactoryGirl.create(:ansible_configuration_script, :manager_id => manager.id)
  end
  let(:svc_job_template) { jt_class.find(job_template.id) }
  let(:ip_addr) { '1.1.1.1' }
  let(:job) { FactoryGirl.create(:ansible_tower_job) }
  let(:svc_job) { job_class.find(job.id) }
  let(:current_object) { Spec::Support::MiqAeMockObject.new('a' => 1, 'b' => 2) }
  let(:root_object) { Spec::Support::MiqAeMockObject.new('param1' => "x=X", 'param2' => "y=Y") }
  let(:middle_object) { Spec::Support::MiqAeMockObject.new('a' => 1, 'b' => 2) }

  let(:ext_vars) { {} }
  let(:job_args) { {:extra_vars => ext_vars} }

  let(:service) { Spec::Support::MiqAeMockService.new(root_object) }

  let(:ems) do
    FactoryGirl.create(:ems_amazon_with_authentication)
  end

  let(:vm_template) do
    FactoryGirl.create(:template_amazon,
                       :name                  => "template1",
                       :ext_management_system => ems)
  end

  let(:prov_options) do
    {:src_vm_id => vm_template.id}
  end

  let(:miq_provision) do
    FactoryGirl.create(:miq_provision_amazon,
                       :options => prov_options,
                       :userid  => user.userid,
                       :state   => 'active',
                       :status  => 'Ok')
  end

  let(:svc_provision) { MiqAeMethodService::MiqAeServiceMiqProvision.find(miq_provision.id) }

  it "run a job using job template name" do
    ext_vars['x'] = 'X'
    ext_vars['y'] = 'Y'
    root_object['vm'] = svc_vm
    current_object = Spec::Support::MiqAeMockObject.new(:job_template_name => job_template.name)
    current_object.parent = root_object
    service.object = current_object
    job_args[:limit] = vm.name

    expect(svc_job_template).to receive(:create_job).with(job_args).and_return(svc_job)
    launch_ansible_job = described_class.new(service)
    expect(launch_ansible_job).to receive(:job_template_by_name).and_return(svc_job_template)
    launch_ansible_job.main
    expect(service.get_state_var(:ansible_job_id)).to eq(job.id)
  end

  it "run a job using job template name and provider name" do
    ext_vars['x'] = 'X'
    ext_vars['y'] = 'Y'
    root_object['vm'] = svc_vm
    current_object = Spec::Support::MiqAeMockObject.new(:job_template_name => job_template.name)
    current_object['ansible_tower_provider_name'] = manager.name
    current_object.parent = root_object
    service.object = current_object
    job_args[:limit] = vm.name

    expect(svc_job_template).to receive(:create_job).with(job_args).and_return(svc_job)
    launch_ansible_job = described_class.new(service)
    expect(launch_ansible_job).to receive(:job_template_by_provider).and_return(svc_job_template)
    launch_ansible_job.main
    expect(service.get_state_var(:ansible_job_id)).to eq(job.id)
  end

  it "run a job using job template name and dialog provider name" do
    ext_vars['x'] = 'X'
    ext_vars['y'] = 'Y'
    root_object['vm'] = svc_vm
    current_object = Spec::Support::MiqAeMockObject.new(:job_template_name => job_template.name)
    current_object['dialog_ansible_tower_provider_name'] = manager.name
    current_object.parent = root_object
    service.object = current_object
    job_args[:limit] = vm.name

    expect(svc_job_template).to receive(:create_job).with(job_args).and_return(svc_job)
    launch_ansible_job = described_class.new(service)
    expect(launch_ansible_job).to receive(:job_template_by_provider).and_return(svc_job_template)
    launch_ansible_job.main
    expect(service.get_state_var(:ansible_job_id)).to eq(job.id)
  end

  it "run a job using job template id" do
    ext_vars['x'] = 'X'
    ext_vars['y'] = 'Y'
    root_object['vm'] = svc_vm
    current_object = Spec::Support::MiqAeMockObject.new(:job_template_id => job_template.id)
    current_object.parent = root_object
    service.object = current_object
    job_args[:limit] = vm.name

    expect(svc_job_template).to receive(:create_job).with(job_args).and_return(svc_job)
    launch_ansible_job = described_class.new(service)
    expect(launch_ansible_job).to receive(:job_template_by_id).and_return(svc_job_template)
    launch_ansible_job.main
    expect(service.get_state_var(:ansible_job_id)).to eq(job.id)
  end

  it "run a job using job template object" do
    ext_vars['x'] = 'X'
    ext_vars['y'] = 'Y'
    root_object['vm'] = svc_vm
    current_object = Spec::Support::MiqAeMockObject.new(:job_template => svc_job_template)
    current_object.parent = root_object
    service.object = current_object
    job_args[:limit] = vm.name

    expect(svc_job_template).to receive(:create_job).with(job_args).and_return(svc_job)
    described_class.new(service).main
    expect(service.get_state_var(:ansible_job_id)).to eq(job.id)
  end

  it "extra vars from current object" do
    root_object['vm'] = svc_vm
    root_object[:job_template_name] = job_template.name
    ext_vars['x'] = '1'
    ext_vars['y'] = '2'
    job_args[:limit] = vm.name
    current_object = Spec::Support::MiqAeMockObject.new('param1' => 'x=1', 'param2' => 'y=2')
    current_object.parent = root_object
    service.object = current_object

    expect(svc_job_template).to receive(:create_job).with(job_args).and_return(svc_job)
    launch_ansible_job = described_class.new(service)
    expect(launch_ansible_job).to receive(:job_template_by_name).and_return(svc_job_template)
    launch_ansible_job.main
    expect(service.get_state_var(:ansible_job_id)).to eq(job.id)
  end

  it "extra vars from dialog params" do
    root_object['vm'] = svc_vm
    root_object[:job_template_name] = job_template.name
    ext_vars['x'] = '1'
    ext_vars['y'] = '2'
    job_args[:limit] = vm.name
    current_object = Spec::Support::MiqAeMockObject.new('dialog_param_x' => '1', 'dialog_param_y' => '2')
    current_object.parent = root_object
    service.object = current_object

    expect(svc_job_template).to receive(:create_job).with(job_args).and_return(svc_job)
    launch_ansible_job = described_class.new(service)
    expect(launch_ansible_job).to receive(:job_template_by_name).and_return(svc_job_template)
    launch_ansible_job.main
    expect(service.get_state_var(:ansible_job_id)).to eq(job.id)
  end

  it "use limit from job template" do
    root_object[:job_template_name] = job_template.name
    ext_vars['x'] = '1'
    ext_vars['y'] = '2'
    current_object = Spec::Support::MiqAeMockObject.new('param1' => 'x=1', 'param2' => 'y=2')
    current_object.parent = root_object
    service.object = current_object

    expect(svc_job_template).to receive(:create_job).with(job_args).and_return(svc_job)
    launch_ansible_job = described_class.new(service)
    expect(launch_ansible_job).to receive(:job_template_by_name).and_return(svc_job_template)
    launch_ansible_job.main
    expect(service.get_state_var(:ansible_job_id)).to eq(job.id)
  end

  it "get dialog parameters" do
    prov_options[:dialog_param_name] = 'fred'
    ext_vars['name'] = 'fred'
    root = Spec::Support::MiqAeMockObject.new(:job_template_name => job_template.name)
    root[:miq_provision] = svc_provision
    service = Spec::Support::MiqAeMockService.new(root)
    service.object = root
    expect(svc_job_template).to receive(:create_job).with(job_args).and_return(svc_job)
    launch_ansible_job = described_class.new(service)
    expect(launch_ansible_job).to receive(:job_template_by_name).and_return(svc_job_template)
    launch_ansible_job.main
    expect(service.get_state_var(:ansible_job_id)).to eq(job.id)
  end

  describe "workflow template" do
    let(:workflow_job_class) { MiqAeMethodService::MiqAeServiceManageIQ_Providers_AnsibleTower_AutomationManager_WorkflowJob }
    let(:workflow_jt_class) { MiqAeMethodService::MiqAeServiceManageIQ_Providers_AnsibleTower_AutomationManager_ConfigurationWorkflow }
    let(:workflow_job) { FactoryBot.create(:ansible_tower_workflow_job) }
    let(:svc_workflow_job) { workflow_job_class.find(workflow_job.id) }
    let(:workflow_template) { FactoryBot.create(:configuration_workflow, :manager_id => manager.id) }
    let(:svc_workflow_template) { workflow_jt_class.find(workflow_template.id) }

    it "run a workflow job using workflow template object" do
      ext_vars['x'] = 'X'
      ext_vars['y'] = 'Y'
      root_object['vm'] = svc_vm
      current_object = Spec::Support::MiqAeMockObject.new(:job_template => svc_workflow_template)
      current_object.parent = root_object
      service.object = current_object
      job_args[:limit] = vm.name
      expect(svc_workflow_template).to receive(:create_job).with(job_args).and_return(svc_workflow_job)
      described_class.new(service).main
      expect(service.get_state_var(:ansible_job_id)).to eq(svc_workflow_job.id)
    end
  end
end
