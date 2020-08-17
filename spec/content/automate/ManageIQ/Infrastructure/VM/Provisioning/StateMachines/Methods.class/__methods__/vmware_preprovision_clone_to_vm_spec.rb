require_domain_file

describe ManageIQ::Automate::Infrastructure::VM::Provisioning::StateMachines::Methods::VmwarePreprovisionCloneToVm do
  let(:ems)         { FactoryBot.create(:ems_vmware_with_authentication) }
  let(:os)          { FactoryBot.create(:operating_system, :product_name => 'Fedora') }
  let(:template)    { FactoryBot.create(:miq_template, :ext_management_system => ems, :operating_system => os) }
  let(:prov_req)    { FactoryBot.create(:miq_provision_request, :options => prov_opt) }
  let(:prov)        { FactoryBot.create(:miq_provision_vmware, :miq_provision_request => prov_req, :options => prov_opt, :request_type => 'clone_to_vm') }
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

  def run_method_with_options(options)
    described_class.new(ae_service).instance_eval do
      @vlan       = options[:vlan]       || false
      @notes      = options[:notes]      || true
      @tags       = options[:tags]       || true
      @customspec = options[:customspec] || false
      main
    end
  end

  def build_notes
    res = "Owner: #{prov_opt[:owner_first_name]} #{prov_opt[:owner_last_name]}\n"\
          "Email: #{prov_opt[:owner_email]}\n"\
          "Source VM: #{template.name}"

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

  it 'sets the tags' do
    tag = category.children.first
    svc_template = MiqAeMethodService::MiqAeServiceMiqTemplate.find(template.id)
    allow(ae_service.root["miq_provision"]).to receive(:vm_template).and_return(svc_template)
    allow(svc_template).to receive(:tags).and_return(["#{category.name}/#{tag.name}"])

    expect(ae_service.root["miq_provision"]).to receive(:add_tag).with(category.name, tag.name)
    described_class.new(ae_service).main
  end

  it 'sets the custom_spec' do
    custom_spec = "my-custom-spec"
    expect(ae_service.root["miq_provision"]).to receive(:set_customization_spec).with(custom_spec)
    run_method_with_options(:customspec => true)
  end

  it 'skips the custom_spec set' do
    os.product_name = 'Other'
    expect(ae_service.root["miq_provision"]).not_to receive(:set_customization_spec)
    run_method_with_options(:customspec => true)
  end

  it 'sets the vlan' do
    default_vlan = "vlan1"
    expect(ae_service.root["miq_provision"]).to receive(:set_vlan).with(default_vlan)
    run_method_with_options(:vlan => true)
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
