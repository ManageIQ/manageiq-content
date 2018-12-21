require_domain_file

describe ManageIQ::Automate::Infrastructure::VM::Transform::Import::ListClusters do
  let(:provider) { FactoryBot.create(:ems_redhat, :with_clusters) }

  let(:root_object) do
    Spec::Support::MiqAeMockObject.new(
      'dialog_provider' => provider.id.to_s
    )
  end

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  it 'should list clusters of selected infra provider' do
    described_class.new(ae_service).main

    expect(ae_service.object['sort_by']).to eq(:description)
    expect(ae_service.object['data_type']).to eq(:string)
    expect(ae_service.object['required']).to eq(true)

    clusters = { nil => '-- select cluster from list --' }
    provider.ems_clusters.each { |cluster| clusters[cluster.id] = cluster.name }

    expect(ae_service.object['values']).to eq(clusters)
  end
end
