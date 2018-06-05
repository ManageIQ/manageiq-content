require_domain_file

describe ManageIQ::Automate::System::Notification::Email::HostAlertCustomizeBody do
  let(:host_url) { "https://www.manageiq.org/show/host/1" }
  let(:miq_alert_description) { "fred" }
  let(:miq_server) { EvmSpecHelper.local_miq_server }
  let(:user) { FactoryGirl.create(:user_with_email_and_group) }
  let(:ems) { FactoryGirl.create(:ems_vmware_with_authentication) }
  let(:svc_host) { MiqAeMethodService::MiqAeServiceHost.find(host.id) }

  let(:host) do
    FactoryGirl.create(:host_vmware,
                       :hardware              => hardware,
                       :ext_management_system => ems)
  end

  let(:hardware) do
    FactoryGirl.create(:hardware,
                       :guest_os => 'linux')
  end

  let(:root_hash) do
    {
      'host'                  => svc_host,
      'user'                  => MiqAeMethodService::MiqAeServiceUser.find(user.id),
      'miq_alert_description' => 'fred',
      'miq_server'            => MiqAeMethodService::MiqAeServiceMiqServer.find(miq_server.id)
    }
  end

  let(:root_object) { Spec::Support::MiqAeMockObject.new(root_hash) }
  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new(
        'to'        => 'touser@example.com',
        'signature' => 'Virtualization Infrastructure Team',
        'from'      => 'fromuser@example.com'
      )
      current_object.parent = root_object
      service.object = current_object
    end
  end

  it "Check object values" do
    allow(svc_host).to receive(:show_url).and_return(host_url)
    described_class.new(ae_service).main

    expect(ae_service.object.attributes).to include(
      'to'        => 'touser@example.com',
      'signature' => 'Virtualization Infrastructure Team',
      'from'      => 'fromuser@example.com'
    )

    expect(ae_service.object['subject']).to eq("#{miq_alert_description} | Host: [#{host.name}]")
  end

  it "Check body values" do
    allow(svc_host).to receive(:show_url).and_return(host_url)
    described_class.new(ae_service).main

    expect(ae_service.object['body']).to include(host_url)
    expect(ae_service.object['body']).to include('Cores per Socket:')
  end

  context "with no objects" do
    let(:root_hash) { {} }

    it "raises the ERROR - Host not found in exception" do
      expect { described_class.new(ae_service).main }.to raise_error(
        'ERROR - Host not found'
      )
    end
  end
end
