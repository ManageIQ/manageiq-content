require_domain_file

describe ManageIQ::Automate::AutomationManagement::AnsibleTower::Service::Provisioning::StateMachines::Provision::Preprovision do
  let(:ansible_tower_manager) { FactoryBot.create(:configuration_manager) }
  let(:job_template) { FactoryBot.create(:ansible_configuration_script, :manager => ansible_tower_manager) }
  let(:service_ansible_tower) { FactoryBot.create(:service_ansible_tower, :job_template => job_template) }
  let(:task) { FactoryBot.create(:service_template_provision_task, :destination => service_ansible_tower) }
  let(:svc_task) { MiqAeMethodService::MiqAeServiceServiceTemplateProvisionTask.find(task.id) }
  let(:root_object) { Spec::Support::MiqAeMockObject.new('service_template_provision_task' => svc_task) }
  let(:ae_service) { Spec::Support::MiqAeMockService.new(root_object) }

  it "examines request configuration" do
    expect_any_instance_of(ServiceAnsibleTower).to receive(:configuration_manager).and_return(ansible_tower_manager)
    expect_any_instance_of(ServiceAnsibleTower).to receive(:job_template).at_least(1).times.and_return(job_template)
    described_class.new(ae_service).main
  end

  it "modifies job options" do
    test = described_class.new(ae_service)
    test.send(:modify_job_options, test.service)
    service_ansible_tower.reload
    expect(service_ansible_tower.job_options).to eq(:limit => 'someHost', :extra_vars => {'flavor' => 'm1.small'})
  end
end
