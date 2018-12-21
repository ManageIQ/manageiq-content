require_domain_file

describe ManageIQ::Automate::Cloud::VM::Provisioning::Placement::BestFitAzure do
  let(:root_object)    { Spec::Support::MiqAeMockObject.new.tap { |ro| ro["miq_provision"] = svc_provision } }
  let(:ems)            { FactoryBot.create(:ems_azure_with_authentication) }
  let(:network)        { FactoryBot.create(:cloud_network) }
  let(:subnet)         { FactoryBot.create(:cloud_subnet) }
  let(:prov_options)   { { :src_vm_id => vm_template.id } }
  let(:miq_provision)  { FactoryBot.create(:miq_provision, :options => prov_options) }
  let(:vm_template)    { FactoryBot.create(:template_azure, :ext_management_system => ems) }
  let(:resource_group) { FactoryBot.create(:resource_group) }

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  let(:svc_provision)      { MiqAeMethodService::MiqAeServiceMiqProvision.find(miq_provision.id) }
  let(:svc_network)        { MiqAeMethodService::MiqAeServiceCloudNetwork.find(network.id) }
  let(:svc_subnet)         { MiqAeMethodService::MiqAeServiceCloudSubnet.find(subnet.id) }
  let(:svc_resource_group) { MiqAeMethodService::MiqAeServiceResourceGroup.find(resource_group.id) }

  it "sets properties" do
    expect(svc_provision).to(receive(:eligible_cloud_networks) { [svc_network] })
    expect(svc_provision).to(receive(:eligible_cloud_subnets) { [svc_subnet] })
    expect(svc_provision).to(receive(:eligible_resource_groups) { [svc_resource_group] })
    expect(svc_provision).to(receive(:set_cloud_network).with(svc_network))
    expect(svc_provision).to(receive(:set_cloud_subnet).with(svc_subnet))
    expect(svc_provision).to(receive(:set_resource_group).with(svc_resource_group))
    described_class.new(ae_service).main
  end

  context 'raises error' do
    it "#'miq_provision not provided'" do
      root_object['miq_provision'] = nil
      expect { described_class.new(ae_service).main }.to(raise_error('miq_provision not provided'))
    end

    it "#'Image not specified'" do
      allow(svc_provision).to(receive(:vm_template) { nil })
      expect { described_class.new(ae_service).main }.to(raise_error('Image not specified'))
    end
  end
end
