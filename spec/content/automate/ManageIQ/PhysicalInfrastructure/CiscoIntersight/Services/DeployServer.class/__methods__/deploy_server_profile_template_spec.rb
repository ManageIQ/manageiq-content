require_domain_file

describe ManageIQ::Automate::PhysicalInfrastructure::CiscoIntersight::Services::DeployServer::Methods::DeployServerProfileTemplate do
  let(:ems) { FactoryBot.create(:ems_cisco_intersight_physical_infra, :auth) }

  let(:physical_server_profile_template) { FactoryBot.create(:physical_server_profile_template, :ext_management_system => ems) }

  let(:physical_server_profile_template_second) { FactoryBot.create(:physical_server_profile_template, :ext_management_system => ems) }

  let(:service_template) { FactoryBot.create(:service_template, :options => {:server_profile_template_id => physical_server_profile_template.id}) }

  let(:task) { FactoryBot.create(:service_template_provision_task, :source => service_template) }

  let(:root_hash) do
    {
      :service_template                => service_template,
      :dialog_name                     => 'test_profile',
      :dialog_server                   => 'server_ems_ref',
      :dialog_template                 => physical_server_profile_template_second.id,
      :service_template_provision_task => task
    }
  end
  let(:root_object) { Spec::Support::MiqAeMockObject.new(root_hash) }

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  it "with server profile template pre selected" do
    described_class.new(ae_service).main
    queue_item = MiqQueue.first
    expect(queue_item.method_name).to eq("deploy_server_from_template")
    expect(queue_item.class_name).to eq("PhysicalServerProfileTemplate")
    expect(queue_item.instance_id).to eq(physical_server_profile_template.id)

  end

  it "without server profile template pre selected" do
    service_template.options[:server_profile_template_id] = nil
    described_class.new(ae_service).main
    queue_item = MiqQueue.first
    expect(queue_item.method_name).to eq("deploy_server_from_template")
    expect(queue_item.class_name).to eq("PhysicalServerProfileTemplate")
    expect(queue_item.instance_id).to eq(physical_server_profile_template_second.id)
  end
end
