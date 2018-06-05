require_domain_file

describe ManageIQ::Automate::System::Notification::Email::VmAlertCustomizeBody do
  let(:vm_url) { "https://www.manageiq.org/show/vm/1" }
  let(:miq_alert_description) { "fred" }
  let(:root_hash) do
    {
      'vm'                    => svc_vm,
      'user'                  => MiqAeMethodService::MiqAeServiceUser.find(user.id),
      'miq_alert_description' => 'fred',
      'miq_server'            => MiqAeMethodService::MiqAeServiceMiqServer.find(miq_server.id)
    }
  end

  let(:root_object) { Spec::Support::MiqAeMockObject.new(root_hash) }
  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new(
        'signature' => 'Virtualization Infrastructure Team'
      )
      current_object.parent = root_object
      service.object = current_object
    end
  end

  let(:miq_server) { EvmSpecHelper.local_miq_server }
  let(:user) { FactoryGirl.create(:user_with_email_and_group) }
  let(:ems) { FactoryGirl.create(:ems_vmware_with_authentication) }
  let(:svc_vm) { MiqAeMethodService::MiqAeServiceVm.find(vm.id) }
  let(:operating_system) { FactoryGirl.create(:operating_system, :product_name => 'fred') }
  let(:vm) do
    FactoryGirl.create(:vm_vmware,
                       :evm_owner        => user,
                       :operating_system => operating_system,
                       :ems_id           => ems.id)
  end

  it "Check object values" do
    allow(svc_vm).to receive(:show_url).and_return(vm_url)
    described_class.new(ae_service).main

    expect(ae_service.object.attributes).to include(
      'signature' => 'Virtualization Infrastructure Team'
    )

    expect(ae_service.object['subject']).to eq("#{miq_alert_description} | VM: [#{vm.name}]")
  end

  it "Check body values" do
    allow(svc_vm).to receive(:show_url).and_return(vm_url)
    described_class.new(ae_service).main

    expect(ae_service.object['body']).to include(vm_url)
    expect(ae_service.object['body']).to include('Operating System:')
  end

  context "with no objects" do
    let(:root_hash) { {} }

    it "raises the ERROR - vm not found in exception" do
      expect { described_class.new(ae_service).main }.to raise_error(
        'ERROR - vm not found'
      )
    end
  end
end
