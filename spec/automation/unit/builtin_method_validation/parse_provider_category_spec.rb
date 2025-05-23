describe "parse_provider_category" do
  let(:infra_ems)        { FactoryBot.create(:ems_vmware_with_authentication) }
  let(:infra_vm)         { FactoryBot.create(:vm_vmware, :ems_id => infra_ems.id, :evm_owner => user) }
  let(:migrate_request)  { FactoryBot.create(:vm_migrate_request, :requester => user) }
  let(:user)             { FactoryBot.create(:user_with_group) }
  let(:inst)             { "/System/Process/parse_provider_category" }
  let(:orch_retire_task) { FactoryBot.create(:orchestration_stack_retire_task) }

  let(:infra_miq_request_task) do
    FactoryBot.create(:miq_request_task, :miq_request => migrate_request, :source => infra_vm)
  end

  let(:infra_vm_template) do
    FactoryBot.create(:template_vmware,
                      :name                  => "template1",
                      :ext_management_system => infra_ems)
  end

  let(:infra_miq_provision) do
    FactoryBot.create(:miq_provision_vmware,
                      :options      => {:src_vm_id => infra_vm_template.id},
                      :userid       => user.userid,
                      :request_type => :clone_to_vm,
                      :status       => 'Ok')
  end

  let(:infra_miq_provision_request) do
    FactoryBot.create(:miq_provision_request,
                       :provision_type => 'template',
                       :state => 'pending', :status => 'Ok',
                       :src_vm_id => infra_vm_template.id,
                       :requester => user)
  end

  let(:cloud_ems) { FactoryBot.create(:ems_amazon_with_authentication) }
  let(:cloud_vm)  { FactoryBot.create(:vm_amazon, :ems_id => cloud_ems.id, :evm_owner => user) }
  let(:stack)     { FactoryBot.create(:orchestration_stack_amazon, :ext_management_system => cloud_ems) }

  let(:cloud_vm_template) do
    FactoryBot.create(:template_amazon,
                       :name                  => "template1",
                       :ext_management_system => cloud_ems)
  end

  let(:cloud_miq_provision) do
    FactoryBot.create(:miq_provision_amazon,
                       :options => {:src_vm_id => cloud_vm_template.id},
                       :userid  => user.userid,
                       :state   => 'active',
                       :status  => 'Ok')
  end

  context "#parse_provider_category for cloud objects" do
    it "for VM" do
      ws = MiqAeEngine.instantiate("#{inst}?Vm::vm=#{cloud_vm.id}", user)
      expect(ws.root["ae_provider_category"]).to eq("cloud")
    end

    it "for orchestration stack" do
      ws = MiqAeEngine.instantiate("#{inst}?OrchestrationStack::orchestration_stack=#{stack.id}", user)
      expect(ws.root["ae_provider_category"]).to eq("cloud")
    end

    it "for orchestration stack retire task" do
      ws = MiqAeEngine.instantiate("#{inst}?OrchestrationStack::orchestration_stack_retire_task=#{stack.id}", user)
      expect(ws.root["ae_provider_category"]).to eq("cloud")
    end

    it "for miq_provision" do
      ws = MiqAeEngine.instantiate("#{inst}?MiqProvision::miq_provision=#{cloud_miq_provision.id}", user)
      expect(ws.root["ae_provider_category"]).to eq("cloud")
    end
  end

  context "#parse_provider_category for infrastructure objects" do
    it "for miq_provision" do
      ws = MiqAeEngine.instantiate("#{inst}?MiqProvision::miq_provision=#{infra_miq_provision.id}", user)
      expect(ws.root["ae_provider_category"]).to eq("infrastructure")
    end

    it "for miq_request" do
      ws = MiqAeEngine.instantiate("#{inst}?MiqRequest::miq_request=#{infra_miq_provision_request.id}", user)
      expect(ws.root["ae_provider_category"]).to eq("infrastructure")
    end

    it "for vm_migrate_request" do
      ws = MiqAeEngine.instantiate("#{inst}?MiqRequestTask::vm_migrate_task=#{infra_miq_request_task.id}", user)
      expect(ws.root["ae_provider_category"]).to eq("infrastructure")
    end
  end

  context "#parse_provider_category for platform_category" do
    it "for cloud platform_category" do
      ws = MiqAeEngine.instantiate("#{inst}?platform_category=cloud", user)
      expect(ws.root["ae_provider_category"]).to eq("cloud")
    end

    it "for infra platform_category" do
      ws = MiqAeEngine.instantiate("#{inst}?platform_category=infra", user)
      expect(ws.root["ae_provider_category"]).to eq("infrastructure")
    end
  end
end
