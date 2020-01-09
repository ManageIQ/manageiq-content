require_domain_file

describe ManageIQ::Automate::Cloud::VM::Provisioning::StateMachines::Methods::AmazonCustomizeRequest do
  let(:ems)         { FactoryBot.create(:ems_amazon_with_authentication) }
  let(:template)    { FactoryBot.create(:miq_template, :ext_management_system => ems) }
  let(:prov_req)    { FactoryBot.create(:miq_provision_request, :options => {:src_vm_id => template.id}) }
  let(:prov)        { FactoryBot.create(:miq_provision, :miq_provision_request => prov_req, :options => {:src_vm_id => template.id}) }
  let(:svc_prov)    { MiqAeMethodService::MiqAeServiceMiqProvision.find(prov.id) }
  let(:root_hash)   { {'miq_provision' => svc_prov} }
  let(:root_object) { Spec::Support::MiqAeMockObject.new(root_hash) }
  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  it "process customization without mapping" do
    described_class.new(ae_service).main
    expect(svc_prov.message).to eq("Processing Amazon customizations...Complete")
  end

  context 'customization with mapping' do
    let(:customization_template) { FactoryBot.create(:customization_template) }

    after(:each) { expect(svc_prov.message).to eq("Processing Amazon customizations...Complete") }

    def options_with_template(ws_values)
      ae_service.root["miq_provision"].options[:ws_values] = ws_values
      ae_service.root["miq_provision"].options[:customization_template_id] = customization_template.id
      ae_service.root["miq_provision"].options[:customization_template_script] = customization_template.script
    end

    context '#instance_type' do
      let(:ems)    { FactoryBot.create(:ems_amazon_with_authentication, :flavors => [flavor]) }
      let(:flavor) { FactoryBot.create(:flavor, :description => 'desc') }

      it "sets flavor as an instance_type" do
        options_with_template(:instance_type => flavor.name)

        described_class.new(ae_service).instance_eval do
          @mapping = true
          main
        end
        expect(svc_prov.options[:instance_type]).to eq([flavor.id, "#{flavor.name}':'#{flavor.description}"])
      end
    end

    context '#guest_access_key_pair' do
      let(:keypair) { FactoryBot.create(:auth_key_pair_cloud, :name => "test_auth_key_pair_cloud") }
      let(:ems)     { FactoryBot.create(:ems_amazon_with_authentication, :key_pairs => [keypair]) }

      it "sets keypair as a guest_access_key_pair" do
        options_with_template(:guest_access_key_pair => keypair.name)

        described_class.new(ae_service).instance_eval do
          @mapping = true
          main
        end
        expect(svc_prov.options[:guest_access_key_pair]).to eq([keypair.id, keypair.name])
      end
    end

    context '#security_groups' do
      let(:sec_group) { FactoryBot.create(:security_group_amazon) }

      it "sets security_groups for network_manager" do
        options_with_template(:security_groups => sec_group.name)
        ems.network_manager.security_groups = [sec_group]

        described_class.new(ae_service).instance_eval do
          @mapping = true
          main
        end
        expect(svc_prov.options[:security_groups]).to eq([sec_group.id])
      end
    end

    context '#customization_templates' do
      it "fails to find template" do
        allow(ae_service.root["miq_provision"]).to receive(:eligible_customization_templates).and_return([])
        expect(ae_service.root["miq_provision"]).not_to receive(:set_customization_template)

        described_class.new(ae_service).instance_eval do
          @mapping = true
          main
        end
      end

      it "finds a template by name" do
        customization_template.name = template.name
        allow(ae_service.root["miq_provision"]).to receive(:eligible_customization_templates).and_return([customization_template])
        expect(ae_service.root["miq_provision"]).to receive(:set_customization_template).with(customization_template)

        described_class.new(ae_service).instance_eval do
          @mapping = true
          main
        end
      end

      it "finds a template by ws_values" do
        ae_service.root["miq_provision"].options[:ws_values] = {:customization_template => customization_template.name}
        allow(ae_service.root["miq_provision"]).to receive(:eligible_customization_templates).and_return([customization_template])
        expect(ae_service.root["miq_provision"]).to receive(:set_customization_template).with(customization_template)

        described_class.new(ae_service).instance_eval do
          @mapping = true
          main
        end
      end

      it "finds a template by functions" do
        customization_template.name = "#{svc_prov.type}_#{svc_prov.get_tags[:function]}"
        allow(ae_service.root["miq_provision"]).to receive(:eligible_customization_templates).and_return([customization_template])
        expect(ae_service.root["miq_provision"]).to receive(:set_customization_template).with(customization_template)

        described_class.new(ae_service).instance_eval do
          @mapping = true
          main
        end
      end
    end
  end

  it 'raises error for missing miq_provision' do
    ae_service.root["miq_provision"] = nil
    expect { described_class.new(ae_service).main }.to raise_error('miq_provision not specified')
  end

  it 'raises error for missing vm_template' do
    allow(ae_service.root["miq_provision"]).to receive(:vm_template).and_return(nil)
    expect { described_class.new(ae_service).main }.to raise_error('vm_template not specified')
  end

  it 'raises error for missing ext_management_system' do
    allow_any_instance_of(MiqAeMethodService::MiqAeServiceMiqTemplate).to receive(:ext_management_system).and_return(nil)
    expect { described_class.new(ae_service).main }.to raise_error('ext_management_system not specified')
  end
end
