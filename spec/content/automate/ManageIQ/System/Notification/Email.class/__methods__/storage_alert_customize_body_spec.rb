require_domain_file

describe ManageIQ::Automate::System::Notification::Email::StorageAlertCustomizeBody do
  let(:storage_url) { "https://www.manageiq.org/show/storage/1" }
  let(:miq_alert_description) { "fred" }
  let(:storage) { FactoryGirl.create(:storage) }
  let(:svc_storage) { MiqAeMethodService::MiqAeServiceStorage.find(storage.id) }
  let(:miq_server) { EvmSpecHelper.local_miq_server }
  let(:user) { FactoryGirl.create(:user_with_email_and_group) }
  let(:ems) { FactoryGirl.create(:ems_vmware_with_authentication) }

  let(:root_hash) do
    {
      'storage'               => svc_storage,
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

  it "Check object values" do
    allow(svc_storage).to receive(:show_url).and_return(storage_url)
    described_class.new(ae_service).main

    expect(ae_service.object.attributes).to include(
      'signature' => 'Virtualization Infrastructure Team'
    )

    expect(ae_service.object['subject']).to eq("#{miq_alert_description} | Datastore: [#{storage.name}]")
  end

  it "Check body values" do
    allow(svc_storage).to receive(:show_url).and_return(storage_url)
    described_class.new(ae_service).main

    expect(ae_service.object['body']).to include(storage_url)
    expect(ae_service.object['body']).to include('Free Space:')
  end

  context "with no objects" do
    let(:root_hash) { {} }

    it "raises the ERROR - storage not found in exception" do
      expect { described_class.new(ae_service).main }.to raise_error(
        'ERROR - storage not found'
      )
    end
  end
end
