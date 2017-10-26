require_domain_file

describe ManageIQ::Automate::Infrastructure::VM::Transform::Import::ListTagNames do
  let(:provider) { FactoryGirl.create(:ems_redhat) }

  let(:root_object) do
    Spec::Support::MiqAeMockObject.new({
        'dialog_provider' => provider.id.to_s,
        'dialog_tag_category' => 'department'
    })
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

    tag_names = { nil => '<Noe>' }
    Classification.find_by_name('department').entries.each do |tag|
      tag_names[tag.name] = tag.description
    end

    expect(ae_service.object['values']).to eq(tag_names)
  end
end
