require_domain_file

describe ManageIQ::Automate::Infrastructure::VM::Transform::Import::ListStorages do
  let(:provider) do
    FactoryGirl.create(:ems_redhat, :hosts => [FactoryGirl.create(:host_redhat, :storage_redhat, :storage_count => 3)])
  end

  let(:vm) { FactoryGirl.create(:vm) }

  let(:root_object) do
    Spec::Support::MiqAeMockObject.new(
      'dialog_provider' => provider.id.to_s,
      'vm'              => vm
    )
  end

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  it 'should list data storages' do
    described_class.new(ae_service).main

    expect(ae_service.object['sort_by']).to eq(:description)
    expect(ae_service.object['data_type']).to eq(:string)
    expect(ae_service.object['required']).to eq(true)

    storages = { nil => '-- select storage from list --' }
    provider.storages.each do |storage|
      storages[storage.id] = storage.name if storage.storage_domain_type == "data"
    end

    expect(ae_service.object['values']).to eq(storages)
    expect(ae_service.object['values'].length).to eq(provider.storages.length) # -1 "iso" item and +1 nil item
  end
end
