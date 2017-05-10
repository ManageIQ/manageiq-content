require_domain_file

describe ManageIQ::Automate::System::Request::OrderAnsiblePlaybook do
  let(:root_object) do
    Spec::Support::MiqAeMockObject.new(attributes)
  end

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  let(:ip1) { "1.1.1.94" }

  let(:vm) { FactoryGirl.create(:vm_vmware, :name => 'fred') }
  let(:svc_vm) { MiqAeMethodService::MiqAeServiceVm.find(vm.id) }

  let(:svc_template) { FactoryGirl.create(:service_template_ansible_playbook, :name => 'fred') }
  let(:svc_service_template) do
    MiqAeMethodService::MiqAeServiceServiceTemplate.find(svc_template.id)
  end

  let(:miq_request) { FactoryGirl.create(:service_template_provision_request) }
  let(:svc_miq_request) do
    MiqAeMethodService::MiqAeServiceMiqRequest.find(miq_request.id)
  end

  let(:svc_vmdb_handle) { MiqAeMethodService::MiqAeServiceServiceTemplate }

  shared_examples_for "order playbook" do
    it "creates request" do
      allow(ae_service).to receive(:vmdb).with('ServiceTemplate').and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:where).with(:name => svc_template.name).and_return([svc_service_template])
      allow(svc_vm).to receive(:ipaddresses).and_return([ip1])
      expect(ae_service).to receive(:create_service_provision_request).with(svc_service_template, extra_vars).and_return(svc_miq_request)

      described_class.new(ae_service).main
    end
  end

  context "with no host" do
    let(:extra_vars) do
      { :hosts       => nil,
        'param_var1' => 'A',
        'param_var2' => 'B' }
    end
    let(:attributes) do
      { 'service_template_name' => svc_service_template.name,
        'dialog_param_var1'     => 'A',
        'dialog_param_var2'     => 'B',
        'vm'                    => svc_vm }
    end

    it_behaves_like "order playbook"

    it "order playbook with incorrect service_template_name should raise error" do
      allow(ae_service).to receive(:vmdb).with('ServiceTemplate').and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:where).with(:name => svc_template.name).and_return([nil])

      expect { described_class.new(ae_service).main }.to raise_error(/not found/)
    end
  end

  context "with no service_template_name" do
    let(:attributes) { {} }
    it "should raise error" do
      expect { described_class.new(ae_service).main }.to raise_error(/service_template_name/)
    end
  end

  context "with vm host" do
    let(:attributes) do
      { 'service_template_name' => svc_service_template.name,
        'dialog_param_var1'     => 'A',
        'dialog_param_var2'     => 'B',
        'hosts'                 => 'vm',
        'vm'                    => svc_vm }
    end

    let(:extra_vars) do
      { :hosts       => ip1,
        'param_var1' => 'A',
        'param_var2' => 'B' }
    end

    it_behaves_like "order playbook"
  end

  context "with vm host but no vm" do
    let(:attributes) do
      { 'service_template_name' => svc_service_template.name,
        'dialog_param_var1'     => 'A',
        'dialog_param_var2'     => 'B',
        'hosts'                 => 'vm' }
    end

    it "raises an error" do
      allow(ae_service).to receive(:vmdb).with('ServiceTemplate').and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:where).with(:name => svc_template.name).and_return([svc_service_template])

      expect { described_class.new(ae_service).main }.to raise_error(/VM object not passed/)
    end
  end

  context "with vm host but no ip address" do
    let(:attributes) do
      { 'service_template_name' => svc_service_template.name,
        'dialog_param_var1'     => 'A',
        'dialog_param_var2'     => 'B',
        'vm'                    => svc_vm,
        'hosts'                 => 'vm' }
    end

    it "raises an error" do
      allow(ae_service).to receive(:vmdb).with('ServiceTemplate').and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:where).with(:name => svc_template.name).and_return([svc_service_template])
      allow(svc_vm).to receive(:ipaddresses).and_return([nil])

      expect { described_class.new(ae_service).main }.to raise_error(/IP address not specified for vm/)
    end
  end
end
