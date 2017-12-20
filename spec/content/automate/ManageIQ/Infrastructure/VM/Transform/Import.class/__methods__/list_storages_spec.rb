require_domain_file

describe ManageIQ::Automate::Infrastructure::VM::Transform::Import::ListStorages do
  let(:provider) { FactoryGirl.create(:ems_redhat, :with_storages) }

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

  it 'should list infra providers supporting VM import' do
    described_class.new(ae_service).main

    expect(ae_service.object['sort_by']).to eq(:description)
    expect(ae_service.object['data_type']).to eq(:string)
    expect(ae_service.object['required']).to eq(false)

    storages = { nil => '-- select storage from list --' }
    provider.storages.each { |storage| storages[storage.id] = storage.name }

    expect(ae_service.object['values']).to eq(storages)
  end
end
