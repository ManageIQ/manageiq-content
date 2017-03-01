require_domain_file

describe ManageIQ::Automate::Cloud::VM::Provisioning::Placement::BestFitAmazon do
  let(:root_object)   { Spec::Support::MiqAeMockObject.new.tap { |ro| ro["miq_provision"] = svc_provision } }
  let(:flavor)        { FactoryGirl.create(:flavor, :name => 'flavor1', :cloud_subnet_required => true) }
  let(:ems)           { FactoryGirl.create(:ems_amazon_with_authentication) }
  let(:network)       { FactoryGirl.create(:cloud_network) }
  let(:subnet)        { FactoryGirl.create(:cloud_subnet) }
  let(:prov_options)  { { :src_vm_id => vm_template.id, :instance_type => flavor.id } }
  let(:miq_provision) { FactoryGirl.create(:miq_provision, :options => prov_options) }
  let(:vm_template)   { FactoryGirl.create(:template_amazon, :ext_management_system => ems) }

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  let(:svc_provision) { MiqAeMethodService::MiqAeServiceMiqProvision.find(miq_provision.id) }
  let(:svc_flavor)    { MiqAeMethodService::MiqAeServiceFlavor.find(flavor.id) }
  let(:svc_network)   { MiqAeMethodService::MiqAeServiceCloudNetwork.find(network.id) }
  let(:svc_subnet)    { MiqAeMethodService::MiqAeServiceCloudSubnet.find(subnet.id) }

  it "setting properties" do
    expect(svc_provision).to receive(:eligible_cloud_networks) { [svc_network] }
    expect(svc_provision).to receive(:eligible_cloud_subnets)  { [svc_subnet] }
    expect(svc_provision).to receive(:set_cloud_network).with(svc_network)
    expect(svc_provision).to receive(:set_cloud_subnet).with(svc_subnet)

    described_class.new(ae_service).main
  end

  it "should raise 'Image not specified'" do
    allow(svc_provision).to receive(:vm_template) { nil }
    expect { described_class.new(ae_service).main }.to raise_error('Image not specified')
  end

  it "should raise 'Instance Type not specified'" do
    prov_options[:instance_type] = nil
    expect { described_class.new(ae_service).main }.to raise_error('Instance Type not specified')
  end
end
