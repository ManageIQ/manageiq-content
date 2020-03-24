require_domain_file

describe ManageIQ::Automate::Infrastructure::VM::Provisioning::StateMachines::Methods::VMwareCustomizeRequest do
  let(:prov_type)   { :miq_provision_vmware }
  let(:ems)         { FactoryBot.create(:ems_redhat_with_authentication) }
  let(:os)          { FactoryBot.create(:operating_system, :product_name => 'suse') }
  let(:template)    { FactoryBot.create(:miq_template, :ext_management_system => ems, :operating_system => os) }
  let(:prov_req)    { FactoryBot.create(:miq_provision_request, :options => {:src_vm_id => template.id}) }
  let(:prov)        { FactoryBot.create(prov_type, :miq_provision_request => prov_req, :request_type => 'template', :options => {:src_vm_id => template.id}) }
  let(:svc_prov)    { MiqAeMethodService::MiqAeServiceMiqProvision.find(prov.id) }
  let(:root_hash)   { {'miq_provision' => svc_prov} }
  let(:root_object) { Spec::Support::MiqAeMockObject.new(root_hash) }
  let(:customization_template) { FactoryBot.create(:customization_template) }
  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  def run_method_with_mapping(level = 1)
    described_class.new(ae_service).instance_eval do
      @mapping = level
      main
    end
  end

  context 'no mapping' do
    let(:prov_type) { :miq_provision }

    it 'skips processing' do
      method = described_class.new(ae_service)
      log = []
      allow(method).to receive(:log) { |level, msg| log << [level, msg] }
      expect(method).not_to receive(:process_vmware)
      expect(method).not_to receive(:process_vmware_pxe)
      method.main
      expect(log.last).to eq([:info, "Provisioning Type: #{prov.type} does not match, skipping processing"])
    end
  end

  context 'VMware' do
    context '#mapping=1' do
      let(:customization_template) { FactoryBot.create(:customization_template) }

      it 'sets customization spec' do
        allow(svc_prov).to receive(:set_customization_spec).with(template.name, true)
        expect(svc_prov).to receive(:set_customization_spec).with(template.name, true)
        expect(svc_prov).to receive(:set_option).with(:linux_host_name, prov.get_option(:vm_target_name))
        expect(svc_prov).to receive(:set_option).with(:vm_target_hostname, prov.get_option(:vm_target_name))

        run_method_with_mapping
      end

      it 'skips mapping for other provision type' do
        os.product_name = '....other....'
        expect(svc_prov).not_to receive(:set_customization_spec)

        run_method_with_mapping
      end
    end

    context '#mapping=2' do
      def validate_final_custom_spec(name, spec)
        os.product_name = name
        allow(svc_prov).to receive(:set_customization_spec).with(spec, true)
        expect(svc_prov).to receive(:set_customization_spec).with(spec, true)

        run_method_with_mapping(2)
      end

      it 'sets spec for Windows Server 2003' do
        validate_final_custom_spec('....2003...', 'W2K3R2-Entx64')
      end

      it 'sets spec for Windows Server 2008' do
        validate_final_custom_spec('....2008...', 'vmware_windows')
      end

      it 'sets spec for Windows7' do
        validate_final_custom_spec('....windows 7...', 'vmware_windows')
      end

      it 'sets spec for Suse' do
        validate_final_custom_spec('....suse....', 'vmware_suse')
      end

      it 'sets spec for RHEL' do
        validate_final_custom_spec('....red hat....', 'vmware_rhel')
      end
    end
  end

  context 'VMware via Pxe' do
    let(:prov_type)   { :miq_provision_vmware_via_pxe }

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
