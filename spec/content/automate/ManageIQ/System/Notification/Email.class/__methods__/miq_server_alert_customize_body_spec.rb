require_domain_file

describe ManageIQ::Automate::System::Notification::Email::MiqServerAlertCustomizeBody do
  let(:miq_server_url) { "https://www.manageiq.org/show/miq_server/1" }
  let(:miq_alert_description) { "fred" }
  let(:ems) { FactoryGirl.create(:ems_vmware_with_authentication) }
  let(:svc_miq_server) { MiqAeMethodService::MiqAeServiceMiqServer.find(miq_server.id) }
  let(:miq_server) { EvmSpecHelper.local_miq_server }
  let(:user) { FactoryGirl.create(:user_with_email_and_group) }

  let(:root_hash) do
    {
      'miq_server'            => svc_miq_server,
      'user'                  => MiqAeMethodService::MiqAeServiceUser.find(user.id),
      'miq_alert_description' => 'fred',
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

  it "Check object values" do
    described_class.new(ae_service).main

    expect(ae_service.object.attributes).to include(
      'signature' => 'Virtualization Infrastructure Team'
    )

    expect(ae_service.object['subject']).to eq("#{miq_alert_description} | EVM Server: [#{miq_server.hostname}]")
  end

  it "Check body values" do
    described_class.new(ae_service).main

    expect(ae_service.object['body']).to include('Last Heartbeat:')
  end

  context "with no objects" do
    let(:root_hash) { {} }

    it "raises the ERROR - miq_server not found in exception" do
      expect { described_class.new(ae_service).main }.to raise_error(
        'ERROR - miq_server not found'
      )
    end
  end
end
