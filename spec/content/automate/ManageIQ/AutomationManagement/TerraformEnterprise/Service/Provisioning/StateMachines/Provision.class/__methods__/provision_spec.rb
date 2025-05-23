require_domain_file

describe ManageIQ::Automate::AutomationManagement::TerraformEnterprise::Service::Provisioning::StateMachines::Provision::Provision do
  let(:admin)       { FactoryBot.create(:user_admin) }
  let(:request)     { FactoryBot.create(:service_template_provision_request, :requester => admin) }
  let(:stack_class) { ManageIQ::Providers::TerraformEnterprise::AutomationManager::OrchestrationStack }
  let(:ems)         { FactoryBot.create(:ems_terraform_enterprise) }
  let(:workspace)   { FactoryBot.create(:configuration_script_terraform_enterprise, :manager => ems) }
  let(:service)     { FactoryBot.create(:service_terraform_enterprise, :terraform_workspace => workspace, :name => "Service Terraform Enterprise", :evm_owner => FactoryBot.create(:user_with_group)) }
  let(:stack)       { FactoryBot.create(:orchestration_stack_terraform_enterprise, :ext_management_system => ems) }
  let(:task)        { FactoryBot.create(:service_template_provision_task, :destination => service, :miq_request => request) }
  let(:svc_task)    { MiqAeMethodService::MiqAeServiceServiceTemplateProvisionTask.find(task.id) }
  let(:root_object) { Spec::Support::MiqAeMockObject.new('service_template_provision_task' => svc_task) }
  let(:ae_service)  { Spec::Support::MiqAeMockService.new(root_object) }

  before { FactoryBot.create(:miq_region, :region => ApplicationRecord.my_region_number) }

  it "launches a Terraform Enterprise Run" do
    expect(stack_class).to receive(:create_stack).and_return(stack)
    described_class.new(ae_service).main
  end

  it "fails the step when stack launching fails" do
    expect(stack_class).to receive(:create_stack).and_raise('provider error')
    described_class.new(ae_service).main
    expect(ae_service.root['ae_result']).to eq('error')
    expect(ae_service.root['ae_reason']).to eq('provider error')
  end
end
