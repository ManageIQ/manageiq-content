require_domain_file

describe ManageIQ::Automate::Cloud::VM::Provisioning::Placement::BestFitGoogle do
  let(:root_object)    { Spec::Support::MiqAeMockObject.new.tap { |ro| ro["miq_provision"] = svc_provision } }
  let(:ems)            { FactoryGirl.create(:ems_google_with_authentication) }
  let(:network)        { FactoryGirl.create(:cloud_network) }
  let(:prov_options)   { { :src_vm_id => vm_template.id } }
  let(:miq_provision)  { FactoryGirl.create(:miq_provision, :options => prov_options) }
  let(:vm_template)    { FactoryGirl.create(:template_google, :ext_management_system => ems) }
  let(:availability_zone) { FactoryGirl.create(:availability_zone) }

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  let(:svc_provision)      { MiqAeMethodService::MiqAeServiceMiqProvision.find(miq_provision.id) }
  let(:svc_network)        { MiqAeMethodService::MiqAeServiceCloudNetwork.find(network.id) }
  let(:svc_zone)           { MiqAeMethodService::MiqAeServiceAvailabilityZone.find(availability_zone.id) }

  it "sets properties" do
    expect(svc_provision).to receive(:eligible_cloud_networks) { [svc_network] }
    expect(svc_provision).to receive(:eligible_availability_zones) { [svc_zone] }
    expect(svc_provision).to receive(:set_cloud_network).with(svc_network)
    expect(svc_provision).to receive(:set_availability_zone).with(svc_zone)

    described_class.new(ae_service).main
  end

  context 'raises exception' do
    it '#miq_provision not provided' do
      ae_service.root["miq_provision"] = nil
      expect { described_class.new(ae_service).main }.to(raise_error('miq_provision not provided'))
    end

    it '#Image not specified' do
      allow(svc_provision).to(receive(:vm_template) { nil })
      expect { described_class.new(ae_service).main }.to(raise_error('Image not specified'))
    end
  end
end
