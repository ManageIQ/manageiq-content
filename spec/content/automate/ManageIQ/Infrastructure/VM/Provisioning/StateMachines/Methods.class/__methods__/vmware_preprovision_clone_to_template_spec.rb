require_domain_file

describe ManageIQ::Automate::Infrastructure::VM::Provisioning::StateMachines::Methods::VmwarePreprovisionCloneToTemplate do
  let(:prov_type)   { :miq_provision_redhat }
  let(:ems)         { FactoryBot.create(:ems_redhat_with_authentication) }
  let(:os)          { FactoryBot.create(:operating_system, :product_name => 'Fedora') }
  let(:template)    { FactoryBot.create(:miq_template, :ext_management_system => ems, :operating_system => os) }
  let(:prov_req)    { FactoryBot.create(:miq_provision_request, :options => prov_opt) }
  let(:prov)        { FactoryBot.create(prov_type, :miq_provision_request => prov_req, :options => prov_opt) }
  let(:svc_prov)    { MiqAeMethodService::MiqAeServiceMiqProvision.find(prov.id) }
  let(:root_hash)   { {'miq_provision' => svc_prov} }
  let(:root_object) { Spec::Support::MiqAeMockObject.new(root_hash) }
  let(:category)    { FactoryBot.create(:classification_department_with_tags) }
  let(:prov_opt)    do
    {
      :src_vm_id        => template.id,
      :owner_first_name => 'owner_first_name',
      :owner_last_name  => 'owner_last_name',
      :owner_email      => 'owner_email@owner_email.com',
      :vm_description   => 'vm_description'
    }
  end
  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  def build_notes
    res = "Owner: #{prov_opt[:owner_first_name]} #{prov_opt[:owner_last_name]}\n"\
          "Email: #{prov_opt[:owner_email]}\n"\
          "Source Template: #{template.name}"

    if ae_service.root["miq_provision"].get_option(:vm_description)
      res += "\nCustom Description: #{prov_opt[:vm_description]}"
    end

    res
  end

  def validate_notes
    described_class.new(ae_service).instance_eval do
      @set_notes = true
      main
    end

    expect(ae_service.root["miq_provision"].get_option(:vm_notes)).to eq(build_notes)
  end

  it 'sets the notes with description' do
    validate_notes
  end

  it 'sets the notes without description' do
    prov_opt[:vm_description] = nil
    validate_notes
  end

  it 'sets the folder' do
    v_owning_datacenter = "v_owning_datacenter"
    svc_template = MiqAeMethodService::MiqAeServiceMiqTemplate.find(template.id)
    allow(ae_service.root["miq_provision"]).to receive(:vm_template).and_return(svc_template)
    allow(svc_template).to receive(:v_owning_datacenter).and_return(v_owning_datacenter)
    expect(ae_service.root["miq_provision"]).to receive(:set_folder).with(v_owning_datacenter)
    described_class.new(ae_service).main
  end

  it 'skips folder set' do
    prov_opt[:placement_folder_name] = 'placement_folder_name'
    expect(ae_service.root["miq_provision"]).not_to receive(:set_folder)
    described_class.new(ae_service).main
  end

  it 'sets the tags' do
    tag = category.children.first
    svc_template = MiqAeMethodService::MiqAeServiceMiqTemplate.find(template.id)
    allow(ae_service.root["miq_provision"]).to receive(:vm_template).and_return(svc_template)
    allow(svc_template).to receive(:tags).and_return(["#{category.name}/#{tag.name}"])

    expect(ae_service.root["miq_provision"]).to receive(:add_tag).with(category.name, tag.name)
    described_class.new(ae_service).main
  end

  it 'raises error for missing miq_provision' do
    ae_service.root["miq_provision"] = nil
    expect { described_class.new(ae_service).main }.to raise_error('miq_provision not specified')
  end

  it 'raises error for missing vm_template' do
    allow(ae_service.root["miq_provision"]).to receive(:vm_template).and_return(nil)
    expect { described_class.new(ae_service).main }.to raise_error('vm_template not specified')
  end
end
