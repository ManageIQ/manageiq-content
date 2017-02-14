require_domain_file

describe ManageIQ::Automate::AutomationManagement::AnsibleTower::Operations::AvailableCredentials do
  let(:ansible_tower_manager) { FactoryGirl.create(:automation_manager_ansible_tower) }
  let(:job_template) do
    FactoryGirl.create(:ansible_configuration_script, :manager => ansible_tower_manager)
  end
  let(:root_object) do
    Spec::Support::MiqAeMockObject.new('service_template' => svc_service_template)
  end
  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
      service.inputs = {'credential_type' => credential_type }
    end
  end
  let(:ra) { {:action => 'Provision', :configuration_template => job_template} }
  let(:svc_template) do
    FactoryGirl.create(:service_template_ansible_playbook).tap do |st|
      st.resource_actions.build(ra)
      st.save
    end
  end
  let(:svc_service_template) do
    MiqAeMethodService::MiqAeServiceServiceTemplate.find(svc_template.id)
  end
  let(:mach_cred1) do
    FactoryGirl.create(:ansible_machine_credential, :resource => ansible_tower_manager)
  end
  let(:mach_cred2) do
    FactoryGirl.create(:ansible_machine_credential, :resource => ansible_tower_manager)
  end
  let(:net_cred1) do
    FactoryGirl.create(:ansible_network_credential, :resource => ansible_tower_manager)
  end
  let(:net_cred2) do
    FactoryGirl.create(:ansible_network_credential, :resource => ansible_tower_manager)
  end

  shared_examples_for "#having only default value" do
    let(:default_desc_blank) { "<none>" }
    it "provides only default value if no credentials" do

      described_class.new(ae_service).main

      expect(ae_service["values"]).to eq(nil => default_desc_blank)
      expect(ae_service["default_value"]).to be_nil
    end
  end


  shared_examples_for "#having specific values based on credential type" do
    it "provides only default value if no credentials" do
      described_class.new(ae_service).main

      expect(ae_service["values"].keys).to match_array(valid_ids)
    end
  end

  context "credentials" do
    before do
      mach_cred1
      mach_cred2
      net_cred1
      net_cred2
    end

    context "machine" do
      let(:credential_type) do
        "ManageIQ::Providers::AnsibleTower::AutomationManager::MachineCredential"
      end
      let(:valid_ids) { [mach_cred1.id, mach_cred2.id, nil] }

      it_behaves_like "#having specific values based on credential type"
    end

    context "network" do
      let(:credential_type) do
        "ManageIQ::Providers::AnsibleTower::AutomationManager::NetworkCredential"
      end
      let(:valid_ids) { [net_cred1.id, net_cred2.id, nil] }

      it_behaves_like "#having specific values based on credential type"
    end
  end

  context "no credentials" do
    context "machine" do
      let(:credential_type) { nil }

      it_behaves_like "#having only default value"
    end
  end
end
