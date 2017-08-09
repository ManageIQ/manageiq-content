require_domain_file

describe ManageIQ::Automate::Infrastructure::VM::Transform::Import::ListInfraProviders do
  let!(:vmware)     { FactoryGirl.create(:ems_vmware) }
  let!(:old_redhat) { FactoryGirl.create(:ems_redhat_v3) }
  let!(:new_redhat) { FactoryGirl.create(:ems_redhat_v4, :api_version => '4.1.5') }

  let(:root_object) { Spec::Support::MiqAeMockObject.new }

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  module ManageIQ::Providers::Redhat::InfraManager::ApiIntegration
    # mock to use DB stored data instead of dynamic runtime values from Cacher
    def supported_api_versions
      [api_version]
    end
  end

  it 'should list infra providers supporting VM import' do
    described_class.new(ae_service).main

    expect(ae_service.object['sort_by']).to eq(:description)
    expect(ae_service.object['data_type']).to eq(:string)
    expect(ae_service.object['required']).to eq(true)
    expect(ae_service.object['values']).to eq(
      nil           => '-- select target infrastructure provider from list --',
      new_redhat.id => new_redhat.name
    )
  end
end
