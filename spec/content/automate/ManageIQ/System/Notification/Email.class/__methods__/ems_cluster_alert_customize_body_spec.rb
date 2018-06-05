require_domain_file

describe ManageIQ::Automate::System::Notification::Email::EmsClusterAlertCustomizeBody do
  let(:ems_cluster_url) { "https://www.manageiq.org/show/ems_cluster/1" }
  let(:miq_alert_description) { "fred" }
  let(:ems)         { FactoryGirl.create(:ems_vmware_with_authentication) }
  let(:ems_cluster) { FactoryGirl.create(:ems_cluster, :ext_management_system => ems) }
  let(:svc_ems_cluster) { MiqAeMethodService::MiqAeServiceEmsCluster.find(ems_cluster.id) }
  let(:miq_server) { EvmSpecHelper.local_miq_server }
  let(:user) { FactoryGirl.create(:user_with_email_and_group) }

  let(:root_hash) do
    {
      'ems_cluster'           => svc_ems_cluster,
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
    allow(svc_ems_cluster).to receive(:show_url).and_return(ems_cluster_url)
    described_class.new(ae_service).main

    expect(ae_service.object.attributes).to include(
      'signature' => 'Virtualization Infrastructure Team'
    )

    expect(ae_service.object['subject']).to eq("#{miq_alert_description} | Cluster: [#{ems_cluster.name}]")
  end

  it "Check body values" do
    allow(svc_ems_cluster).to receive(:show_url).and_return(ems_cluster_url)
    described_class.new(ae_service).main

    expect(ae_service.object['body']).to include(ems_cluster_url)
    expect(ae_service.object['body']).to include('Total Host CPU Cores')
  end

  context "with no objects" do
    let(:root_hash) { {} }

    it "raises the ERROR - ems_cluster not found in exception" do
      expect { described_class.new(ae_service).main }.to raise_error(
        'ERROR - ems_cluster not found'
      )
    end
  end
end
