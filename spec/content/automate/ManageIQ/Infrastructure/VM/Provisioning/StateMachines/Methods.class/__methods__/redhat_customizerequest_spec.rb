require_domain_file

describe ManageIQ::Automate::Infrastructure::VM::Provisioning::StateMachines::Methods::RedhatCustomizeRequest do
  let(:prov_type)   { :miq_provision_redhat }
  let(:ems)         { FactoryBot.create(:ems_redhat_with_authentication) }
  let(:os)          { FactoryBot.create(:operating_system, :product_name => 'Fedora') }
  let(:template)    { FactoryBot.create(:miq_template, :ext_management_system => ems, :operating_system => os) }
  let(:prov_req)    { FactoryBot.create(:miq_provision_request, :options => {:src_vm_id => template.id}) }
  let(:prov)        { FactoryBot.create(prov_type, :miq_provision_request => prov_req, :options => {:src_vm_id => template.id}) }
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

  def run_method_with_mapping
    described_class.new(ae_service).instance_eval do
      @mapping = true
      main
    end
  end

  shared_examples 'no mapping' do
    it 'process customization without mapping' do
      method = described_class.new(ae_service)
      expect(method).not_to receive(:process_redhat)
      expect(method).not_to receive(:process_redhat_iso)
      expect(method).not_to receive(:process_redhat_pxe)
      method.main
    end
  end

  context 'Redhat via Iso' do
    let(:prov_type) { :miq_provision_redhat_via_iso }
    include_examples 'no mapping'

    context '#mapping' do
      let(:iso)                    { FactoryBot.create(:iso_image, :name => 'Test ISO Image') }
      let(:customization_template) { FactoryBot.create(:customization_template) }

      it 'finds iso image and customization template by IDs' do
        svc_prov.options[:iso_image_id] = iso.id
        expect(svc_prov).not_to receive(:eligible_iso_images)
        svc_prov.options[:customization_template_id] = customization_template.id
        expect(svc_prov).not_to receive(:eligible_customization_templates)

        run_method_with_mapping
      end

      it "finds iso image by name" do
        iso.name = template.name
        svc_prov.options[:customization_template_id] = customization_template.id
        allow(svc_prov).to receive(:eligible_iso_images).and_return([iso])
        expect(svc_prov).to receive(:set_iso_image).with(iso)

        run_method_with_mapping
      end

      it 'fails to find iso image' do
        iso.name = template.name
        svc_prov.options[:customization_template_id] = customization_template.id
        allow(svc_prov).to receive(:eligible_iso_images).and_return([])

        expect { run_method_with_mapping }.to raise_error('Failed to find matching ISO Image')
      end

      it 'finds customization template by name' do
        customization_template.name = template.name
        svc_prov.options[:iso_image_id] = iso.id
        allow(svc_prov).to receive(:eligible_customization_templates).and_return([customization_template])
        expect(svc_prov).to receive(:set_customization_template).with(customization_template)

        run_method_with_mapping
      end

      it 'fails to find customization template' do
        customization_template.name = template.name
        svc_prov.options[:iso_image_id] = iso.id
        allow(svc_prov).to receive(:eligible_customization_templates).and_return([])

        expect { run_method_with_mapping }.to raise_error('Failed to find matching Customization Template')
      end

      context '#windows_template' do
        let(:os)  { FactoryBot.create(:operating_system, :product_name => 'Microsoft Windows') }

        it 'skips mapping' do
          method = described_class.new(ae_service)
          expect(method).to receive(:process_redhat_iso)
          expect(svc_prov).not_to receive(:get_option).with(:iso_image_id)
          expect(svc_prov).not_to receive(:get_option).with(:customization_template_id)

          method.instance_eval do
            @mapping = true
            main
          end
        end
      end
    end
  end

  context 'Redhat via Pxe' do
    let(:prov_type)   { :miq_provision_redhat_via_pxe }
    include_examples 'no mapping'

    context '#mapping' do
      let(:pxe)                    { FactoryBot.create(:pxe_image, :name => "Test PXE Image") }
      let(:customization_template) { FactoryBot.create(:customization_template) }

      it 'finds pxe image by name' do
        pxe.name = template.name
        allow(svc_prov).to receive(:eligible_pxe_images).and_return([pxe])
        expect(svc_prov).to receive(:set_pxe_image).with(pxe)
        svc_prov.options[:customization_template_id] = customization_template.id

        run_method_with_mapping
      end

      it 'finds customization template by name' do
        svc_prov.options[:pxe_image_id] = pxe.id
        customization_template.name = template.name
        allow(svc_prov).to receive(:eligible_customization_templates).and_return([customization_template])
        expect(svc_prov).to receive(:set_customization_template).with(customization_template)

        run_method_with_mapping
      end

      context '#windows_template' do
        let(:os)  { FactoryBot.create(:operating_system, :product_name => 'Microsoft Windows') }

        it 'finds pxe image by name' do
          pxe.name = template.name
          allow(svc_prov).to receive(:eligible_windows_images).and_return([pxe])
          expect(svc_prov).to receive(:set_windows_image).with(pxe)
          svc_prov.options[:customization_template_id] = customization_template.id

          run_method_with_mapping
        end

        it 'fails to find iso image' do
          pxe.name = template.name
          allow(svc_prov).to receive(:eligible_windows_images).and_return([])
          svc_prov.options[:customization_template_id] = customization_template.id

          expect { run_method_with_mapping }.to raise_error('Failed to find matching PXE Image')
        end

        it 'finds customization template by name' do
          svc_prov.options[:pxe_image_id] = pxe.id
          customization_template.name = template.name
          allow(svc_prov).to receive(:eligible_customization_templates).and_return([customization_template])
          expect(svc_prov).to receive(:set_customization_template).with(customization_template)

          run_method_with_mapping
        end

        it 'fails to find customization template' do
          svc_prov.options[:pxe_image_id] = pxe.id
          allow(svc_prov).to receive(:eligible_customization_templates).and_return([])
          customization_template.name = template.name

          expect { run_method_with_mapping }.to raise_error('Failed to find matching PXE Image')
        end
      end
    end
  end

  context 'Redhat' do
    include_examples 'no mapping'

    context '#mapping' do
      let(:customization_template) { FactoryBot.create(:customization_template) }

      after(:each) { expect(svc_prov.message).to eq('Processing process_redhat...Complete') }

      it 'finds a template by ID' do
        allow(svc_prov).to receive(:get_option).with(:customization_template_id).twice.and_return(customization_template.id)
        allow(svc_prov).to receive(:get_option).with(:customization_template_script).and_return(customization_template.script)
        expect(svc_prov).not_to receive(:set_customization_template)
        expect(customization_template.script).to receive(:inspect)

        run_method_with_mapping
      end

      it 'finds a template by name' do
        customization_template.name = template.name
        allow(svc_prov).to receive(:eligible_customization_templates).and_return([customization_template])
        expect(svc_prov).to receive(:set_customization_template).with(customization_template)

        run_method_with_mapping
      end

      it 'finds a template by ws_values' do
        svc_prov.options[:ws_values] = {:customization_template => customization_template.name}
        allow(svc_prov).to receive(:eligible_customization_templates).and_return([customization_template])
        expect(svc_prov).to receive(:set_customization_template).with(customization_template)

        run_method_with_mapping
      end

      it 'fails to find a template' do
        allow(svc_prov).to receive(:eligible_customization_templates).and_return([])
        expect(svc_prov).not_to receive(:set_customization_template)

        run_method_with_mapping
      end
    end
  end

  context '#invalid provision type' do
    let(:prov_type) { :miq_provision }

    it 'skips the processing' do
      logs = []
      allow(ae_service).to receive(:log) { |_, msg| logs << msg }
      described_class.new(ae_service).main
      expect(logs[2]).to eq("Provisioning Type: #{prov.type} does not match, skipping processing")
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
