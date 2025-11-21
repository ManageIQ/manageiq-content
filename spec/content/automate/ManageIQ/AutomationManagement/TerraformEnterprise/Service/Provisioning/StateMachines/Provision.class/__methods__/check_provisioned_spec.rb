require_domain_file

describe ManageIQ::Automate::AutomationManagement::TerraformEnterprise::Service::Provisioning::StateMachines::Provision::CheckProvisioned do
  let(:admin)       { FactoryBot.create(:user_admin) }
  let(:request)     { FactoryBot.create(:service_template_provision_request, :requester => admin) }
  let(:service)     { FactoryBot.create(:service_terraform_enterprise, :terraform_workspace => workspace, :name => "Service Terraform Enterprise", :evm_owner => FactoryBot.create(:user_with_group)) }
  let(:workspace)   { FactoryBot.create(:configuration_script_terraform_enterprise, :manager => ems) }
  let(:task)        { FactoryBot.create(:service_template_provision_task, :destination => service, :miq_request => request) }
  let(:svc_task)    { MiqAeMethodService::MiqAeServiceServiceTemplateProvisionTask.find(task.id) }
  let(:ems)         { FactoryBot.create(:ems_terraform_enterprise).tap { |ems| ems.authentications << FactoryBot.create(:auth_token) } }
  let(:root_object) { Spec::Support::MiqAeMockObject.new('service_template_provision_task' => svc_task) }
  let(:ae_service)  { Spec::Support::MiqAeMockService.new(root_object) }
  let(:stack_class) { ManageIQ::Providers::TerraformEnterprise::AutomationManager::OrchestrationStack }
  let(:stack)       { FactoryBot.create(:orchestration_stack_terraform_enterprise, :ext_management_system => ems, :status => status) }

  describe 'check provision status' do
    before { allow_any_instance_of(ServiceTerraformEnterprise).to receive(:stack).and_return(stack) }

    context 'terraform enterprise run completed' do
      let(:status) { "planned_and_finished" }

      it "refreshes the job status" do
        expect(stack).to receive(:refresh_ems)
        described_class.new(ae_service).main
        expect(ae_service.root['ae_result']).to eq('ok')
      end
    end

    context 'terraform enterprise run is running' do
      let(:status) { "plan_queued" }

      it "retries the step" do
        expect(stack).to receive(:refresh_ems)
        described_class.new(ae_service).main
        expect(ae_service.root['ae_result']).to eq('retry')
      end
    end

    context 'terraform enterprise run failed' do
      let(:status) { "errored" }

      it "signals error" do
        expect(stack).to receive(:refresh_ems)
        expect(stack).to receive(:raw_stdout)
        described_class.new(ae_service).main
        expect(ae_service.root['ae_result']).to eq('error')
        expect(ae_service.root['ae_reason']).to eq('The run has errored. This is a final state.')
      end
    end
  end
end
