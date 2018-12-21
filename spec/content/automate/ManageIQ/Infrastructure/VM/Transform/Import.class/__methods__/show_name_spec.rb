require_domain_file

describe ManageIQ::Automate::Infrastructure::VM::Transform::Import::ShowName do
  let(:provider) { FactoryBot.create(:ems_redhat) }

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

  it 'should hide name field if VM is not set' do
    described_class.new(ae_service).main

    expect(ae_service.object['data_type']).to eq(:string)
    expect(ae_service.object['required']).to eq(false)
    expect(ae_service.object['visible']).to eq(false)
  end

  it 'should show name field if VM is set' do
    ae_service.root['vm'] = Spec::Support::MiqAeMockObject.new

    described_class.new(ae_service).main

    expect(ae_service.object['data_type']).to eq(:string)
    expect(ae_service.object['required']).to eq(false)
    expect(ae_service.object['visible']).to eq(true)
  end
end
