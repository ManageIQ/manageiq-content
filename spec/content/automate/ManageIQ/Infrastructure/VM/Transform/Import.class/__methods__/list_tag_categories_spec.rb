require_domain_file

describe ManageIQ::Automate::Infrastructure::VM::Transform::Import::ListTagCategories do
  let(:provider) { FactoryGirl.create(:ems_redhat) }

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

  def create_tags
    FactoryGirl.create(:classification_department_with_tags)
  end

  it 'should return list of categories' do
    create_tags

    described_class.new(ae_service).main

    expect(ae_service.object['sort_by']).to eq(:description)
    expect(ae_service.object['data_type']).to eq(:string)
    expect(ae_service.object['required']).to eq(false)
    expect(ae_service.object['visible']).to eq(true)

    categories = { nil => '<None>' }
    Classification.categories.each do |category|
      categories[category.name] = category.description
    end

    expect(ae_service.object['values']).to eq(categories)
  end
end
